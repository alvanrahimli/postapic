package main

import "time"

type PostsPageData struct {
	Posts []PostDto
}

type SubmitPageData struct {
	Users []UserDto
}

type ErrorPageData struct {
	Message string
	Code    int
}

type UserDto struct {
	UserId   int    `json:"id"`
	UserName string `json:"userName"`
}

type ImageDto struct {
	Url    string `json:"url"`
	Width  int    `json:"width"`
	Height int    `json:"height"`
}

type PostDto struct {
	PostId    int       `json:"id"`
	Title     string    `json:"title"`
	Image     ImageDto  `json:"image"`
	Timestamp time.Time `json:"createdAt"`
	Author    UserDto   `json:"author"`
}

type PostCreateDto struct {
	Title    string
	UserId   int
	ImageKey string
	Width    int
	Height   int
}

type UserPasswordDto struct {
	UserId   int
	Password string
}
