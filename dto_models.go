package main

import "time"

type PostsPageData struct {
	Posts []PostDto
}

type SubmitPageData struct {
	Users []UserDto
}

type UserDto struct {
	UserId   int    `json:"id"`
	UserName string `json:"userName"`
}

type PostDto struct {
	PostId    int       `json:"id"`
	Title     string    `json:"title"`
	ImageUrl  string    `json:"imageUrl"`
	Timestamp time.Time `json:"createdAt"`
	Author    UserDto   `json:"author"`
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
