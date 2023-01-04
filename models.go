package main

import (
	"database/sql"
	"errors"
	"log"
	"net/url"
	"time"
)

type User struct {
	UserId   int    `json:"user_id"`
	UserName string `json:"user_name"`
	Password string `json:"password"`
}

func checkUserPassword(req UserPasswordDto) (bool, int, error) {
	db := getDb()

	row := db.QueryRow("SELECT user_id FROM users WHERE user_id = ? AND password = ?", req.UserId, req.Password)
	err := row.Err()
	if errors.Is(err, sql.ErrNoRows) {
		return false, -1, nil
	} else if err != nil {
		return false, -1, err
	}

	var userId int
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

	_, err := db.Exec("INSERT INTO posts (title, image_key, timestamp, author_id) VALUES (?, ?, ?, ?);",
		req.Title, req.ImageKey, time.Now().Format(time.RFC3339), req.UserId)
	if err != nil {
		return err
	}

	return nil
}

func getAllPosts() ([]PostDto, error) {
	db := getDb()

	rows, err := db.Query(`
SELECT post_id, title, image_key, timestamp, user_name 
FROM posts LEFT JOIN users u on u.user_id = posts.author_id
ORDER BY post_id DESC;`)
	if rows.Err() != nil {
		return nil, rows.Err()
	}

	var posts []PostDto
	for rows.Next() {
		var post PostDto
		var timeStr string
		var imageKey string

		err = rows.Scan(&post.PostId, &post.Title, &imageKey, &timeStr, &post.AuthorName)
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
		post.ImageUrl = finalImgUrl

		posts = append(posts, post)
	}

	return posts, nil
}

func (p PostDto) ReadableTime(timestamp time.Time) string {
	return timestamp.Format("02 Jan 06 15:04")
}
