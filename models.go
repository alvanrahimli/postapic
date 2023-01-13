package main

import (
	"database/sql"
	"errors"
	"github.com/alvanrahimli/postapic/timeago"
	"log"
	"net/url"
	"time"
)

type User struct {
	UserId   int    `json:"user_id"`
	UserName string `json:"user_name"`
	Password string `json:"password"`
}

type Token struct {
	TokenId    int64     `json:"-"`
	Token      string    `json:"token"`
	Expiration time.Time `json:"expiration"`
	UserId     int       `json:"user_id"`
}

func getUserById(id int) (*UserDto, error) {
	db := getDb()

	row := db.QueryRow("SELECT user_id, user_name FROM users WHERE user_id = ?", id)
	if row.Err() != nil {
		return nil, row.Err()
	}

	var user UserDto
	err := row.Scan(&user.UserId, &user.UserName)
	if err != nil {
		return nil, err
	}

	return &user, nil
}

func tryFindUser(req CheckPasswordDto) (succeeded bool, userId int, err error) {
	db := getDb()

	var row *sql.Row

	if req.Username != "" {
		row = db.QueryRow("SELECT user_id FROM users WHERE user_name = ? AND password = ?", req.Username, req.Password)
	} else {
		row = db.QueryRow("SELECT user_id FROM users WHERE user_id = ? AND password = ?", req.UserId, req.Password)
	}

	err = row.Err()
	if errors.Is(err, sql.ErrNoRows) {
		return false, -1, nil
	} else if err != nil {
		return false, -1, err
	}

	err = row.Scan(&userId)
	if err != nil {
		return false, -1, err
	}

	return true, userId, nil
}

func getAllUsers() ([]UserDto, error) {
	db := getDb()

	rows, err := db.Query("SELECT user_id, user_name FROM users ORDER BY user_id;")
	if err != nil {
		log.Printf("Could not query users! err: %s\n", err.Error())
		return nil, err
	}

	var users []UserDto
	for rows.Next() {
		var userDto UserDto

		err = rows.Scan(&userDto.UserId, &userDto.UserName)
		if err != nil {
			return nil, err
		}
		users = append(users, userDto)
	}

	err = rows.Err()
	if err != nil {
		return nil, err
	}

	return users, nil
}

func createPost(req PostCreateDto) error {
	db := getDb()

	_, err := db.Exec(`INSERT INTO posts (title, image_key, image_width, image_height, timestamp, author_id) VALUES (?, ?, ?, ?, ?, ?);`,
		req.Title, req.ImageKey, req.Width, req.Height, time.Now().Format(time.RFC3339), req.UserId)
	if err != nil {
		return err
	}

	return nil
}

func getAllPosts(offset, limit int) ([]PostDto, error) {
	db := getDb()

	rows, err := db.Query(`
SELECT post_id, title, image_key, image_width, image_height, timestamp, author_id, user_name 
FROM posts LEFT JOIN users u on u.user_id = posts.author_id
ORDER BY post_id DESC
LIMIT ? OFFSET ?;`, limit, offset)
	if rows.Err() != nil {
		return nil, rows.Err()
	}

	defer rows.Close()

	var posts = make([]PostDto, 0)
	for rows.Next() {
		var post PostDto
		var timeStr string
		var imageKey string

		err = rows.Scan(&post.PostId, &post.Title, &imageKey, &post.Image.Width, &post.Image.Height,
			&timeStr, &post.Author.UserId, &post.Author.UserName)
		if err != nil {
			return nil, err
		}

		timestamp, err := time.Parse(time.RFC3339, timeStr)
		if err != nil {
			return nil, err
		}
		post.Timestamp = timestamp

		finalImgUrl, err := url.JoinPath("/images/", imageKey)
		if err != nil {
			return nil, err
		}
		post.Image.Url = finalImgUrl

		posts = append(posts, post)
	}

	return posts, nil
}

func (p PostDto) ReadableTime(timestamp time.Time) string {
	return timeago.English.FormatRelativeDuration(time.Now().Local().Sub(timestamp.Local()))
}

func createToken(userId int) (*Token, error) {
	token := &Token{
		Token:      RandSeq(64),
		Expiration: time.Now().Add(time.Hour * 24 * 365).UTC(),
		UserId:     userId,
	}

	db := getDb()

	query, err := db.Prepare("INSERT INTO tokens (token, expiration, user_id) VALUES (?, ?, ?)")
	if err != nil {
		return nil, err
	}

	result, err := query.Exec(token.Token, token.Expiration.Format(time.RFC3339), userId)
	if err != nil {
		return nil, err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return nil, err
	}

	token.TokenId = id
	return token, nil
}

func getAndValidateToken(token string) (*Token, error) {
	db := getDb()

	stmt, err := db.Prepare("SELECT token_id, token, expiration, user_id FROM tokens WHERE token = ?")
	if err != nil {
		return nil, err
	}

	row := stmt.QueryRow(token)
	if err := row.Err(); errors.Is(err, sql.ErrNoRows) {
		return nil, errors.New("could not find token")
	} else if err != nil {
		return nil, err
	}

	var t Token
	var exp string
	err = row.Scan(&t.TokenId, &t.Token, &exp, &t.UserId)
	if err != nil {
		return nil, err
	}

	expTime, err := time.Parse(time.RFC3339, exp)
	if err != nil {
		return nil, err
	}

	if expTime.Before(time.Now().UTC()) {
		return nil, errors.New("token has expired")
	}

	t.Expiration = expTime
	return &t, nil
}
