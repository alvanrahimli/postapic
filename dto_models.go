package main

import "time"

type PostsPageData struct {
	Posts []PostDto
}

type SubmitPageData struct {
	Users []UserDto
}

type UserDto struct {
	UserId   int
	UserName string
}

type PostDto struct {
	PostId    int
	Title     string
	ImageUrl  string
	Timestamp time.Time
	Author    UserDto
}

type PostCreateDto struct {
	Title    string
	UserId   int
	ImageKey string
}

type UserPasswordDto struct {
	UserId   int
	Password string
}
