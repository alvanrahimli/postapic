package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"os"
)

const (
	createUsers = `
CREATE TABLE IF NOT EXISTS users (
	user_id INTEGER PRIMARY KEY,
	user_name TEXT NOT NULL,
	password TEXT NOT NULL
);`
	createPosts = `
CREATE TABLE IF NOT EXISTS posts (
	post_id INTEGER PRIMARY KEY,
	title TEXT,
	timestamp TEXT,
	image_key TEXT NOT NULL,
	author_id INTEGER NOT NULL,
	FOREIGN KEY (author_id)
		REFERENCES users (user_id)
);`
	insertUser = `
INSERT OR IGNORE INTO users (user_id, user_name, password)
VALUES (?, ?, ?);`
)

var dbInternal *sql.DB

func getDb() *sql.DB {
	if dbInternal == nil {
		var err error
		dbInternal, err = sql.Open("sqlite3", "db/postapic.db")
		if err != nil {
			log.Fatalln(err.Error())
		}
	}

	return dbInternal
}

func migrate() error {
	db := getDb()

	usersStmt, err := db.Prepare(createUsers)
	if err != nil {
		return err
	}

	_, err = usersStmt.Exec()
	if err != nil {
		return err
	}

	postStmt, err := db.Prepare(createPosts)
	if err != nil {
		return err
	}
	_, err = postStmt.Exec()
	if err != nil {
		return err
	}

	usersFile := os.Getenv("USERS_LIST_PATH")
	if usersFile == "" {
		usersFile = "db/users.json"
	}
	fileContent, err := os.ReadFile(usersFile)
	if err != nil {
		return err
	}

	var users []User
	err = json.Unmarshal(fileContent, &users)
	if err != nil {
		return err
	}

	for _, user := range users {
		_, err = db.Exec(insertUser, user.UserId, user.UserName, user.Password)
		if err != nil {
			return err
		}
	}

	return nil
}
