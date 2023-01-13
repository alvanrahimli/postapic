package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/alvanrahimli/postapic/image"
	"html/template"
	"log"
	"net/http"
	"net/url"
	"strconv"
	"strings"
)

var tmpl = template.Must(template.ParseGlob("templates/*"))
var imgMgr = image.Manager{
	Directory: "images",
	MaxWidth:  1777,
	MaxHeight: 1000,
}

const MaxUploadBufferSize = 1 << 20 // 1 MiB
const MaxFileSize = 20 << 20        // 20 MiB

func handlePostapic(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		var users []UserDto
		var err error
		users, err = getAllUsers()
		if err != nil {
			log.Printf("could not get users. err: %s\n", err.Error())
			iHopeSo(tmpl.ExecuteTemplate(w, "error.html", ErrorPageData{
				Message: "Could not get users",
				Code:    http.StatusInternalServerError,
			}))
			return
		}

		iHopeSo(tmpl.ExecuteTemplate(w, "postapic.html", SubmitPageData{Users: users}))

	case "POST":
		r.ParseMultipartForm(MaxUploadBufferSize)

		picture, pictureHeader, err := r.FormFile("picture")
		if err != nil {
			log.Printf("Could not get form file. err: %s\n", err.Error())
			handleError(w, "Could not get form file", http.StatusBadRequest)
			return
		}
		if pictureHeader.Size > MaxFileSize {
			log.Printf("Max file upload size exceeded (size: %v)\n", pictureHeader.Size)
			handleError(w, "Max file upload size exceeded", http.StatusRequestEntityTooLarge)
			return
		}
		defer picture.Close()

		userId, err := strconv.Atoi(r.FormValue("user_id"))
		if err != nil {
			handleError(w, "Invalid user id", http.StatusBadRequest)
			return
		}
		userPwdDto := CheckPasswordDto{
			UserId:   userId,
			Password: r.FormValue("password"),
		}
		title := strings.TrimSpace(r.FormValue("title"))

		userExists, userId, err := tryFindUser(userPwdDto)
		if !userExists {
			handleError(w, "User does not exist", http.StatusNotFound)
			return
		} else if err != nil {
			handleError(w, "Something went wrong while validating user", http.StatusInternalServerError)
			return
		}

		imageCtx, err := imgMgr.Upload(picture)
		if err != nil {
			log.Println("error creating file", err.Error())
			handleError(w, "Could not upload image", http.StatusInternalServerError)
			return
		}

		err = createPost(PostCreateDto{
			Title:    title,
			UserId:   userId,
			ImageKey: imageCtx.Key,
			Width:    imageCtx.Width,
			Height:   imageCtx.Height,
		})
		if err != nil {
			log.Printf("could not insert post. err: %s\n", err.Error())
			handleError(w, "Could not post your pic :(", http.StatusInternalServerError)
			return
		}

		http.Redirect(w, r, "/", http.StatusFound)
	}
}

func handleApiPostapic(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, fmt.Sprintf("Method %s is not allowed", r.Method), http.StatusMethodNotAllowed)
		return
	}

	headerParts := strings.Split(r.Header.Get("Authorization"), " ")
	if len(headerParts) != 2 {
		http.Error(w, "Invalid authorization header", http.StatusUnauthorized)
		return
	}
	if headerParts[0] != "Bearer" {
		http.Error(w, "Bearer token required", http.StatusUnauthorized)
		return
	}
	token := headerParts[1]

	title := r.FormValue("title")
	if title == "" {
		http.Error(w, "title is required", http.StatusBadRequest)
		return
	}

	t, err := getAndValidateToken(token)
	if err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	r.ParseMultipartForm(MaxUploadBufferSize)
	picture, pictureHeader, err := r.FormFile("picture")
	if err != nil {
		log.Printf("Could not get form file. err: %s\n", err.Error())
		handleError(w, "Could not get form file", http.StatusBadRequest)
		return
	}
	if pictureHeader.Size > MaxFileSize {
		log.Printf("Max file upload size exceeded (size: %v)\n", pictureHeader.Size)
		handleError(w, "Max file upload size exceeded", http.StatusRequestEntityTooLarge)
		return
	}
	defer picture.Close()

	imageCtx, err := imgMgr.Upload(picture)
	if err != nil {
		log.Println("error creating file", err.Error())
		handleError(w, "Could not upload image", http.StatusInternalServerError)
		return
	}

	err = createPost(PostCreateDto{
		Title:    title,
		UserId:   t.UserId,
		ImageKey: imageCtx.Key,
		Width:    imageCtx.Width,
		Height:   imageCtx.Height,
	})
	if err != nil {
		log.Printf("could not insert post. err: %s\n", err.Error())
		handleError(w, "Could not post your pic :(", http.StatusInternalServerError)
		return
	}
}

func handleGetPosts(w http.ResponseWriter, _ *http.Request) {
	posts, err := getAllPosts(0, 1000)
	if err != nil {
		log.Println(err.Error())
		handleError(w, "Could not get posts", http.StatusInternalServerError)
		return
	}

	iHopeSo(tmpl.ExecuteTemplate(w, "postlist.html", PostsPageData{Posts: posts}))
}

func getIntParam(v url.Values, key string) (value int, ok bool) {
	s := v.Get(key)
	if v, err := strconv.Atoi(s); err == nil {
		return v, true
	} else {
		return 0, false
	}
}

func handleGetPostsApi(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	offset, hasOffset := getIntParam(query, "offset")
	if !hasOffset {
		offset = 0
	}
	limit, hasLimit := getIntParam(query, "limit")
	if !hasLimit {
		limit = 10
	}

	posts, err := getAllPosts(offset, limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Add("content-type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)

	err = json.NewEncoder(w).Encode(posts)
	if err != nil {
		log.Printf("failed to encode: %s", err)
	}
}

func handleRssFeed(w http.ResponseWriter, _ *http.Request) {
	posts, err := getAllPosts(0, 1000)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Build and return page
	var buff bytes.Buffer
	err = tmpl.ExecuteTemplate(&buff, "rss.xml", PostsPageData{Posts: posts})
	if err != nil {
		log.Printf("Could not execute template. err: %s\n", err.Error())
	}

	w.Header().Set("Content-Type", "application/xml")
	_, err = w.Write(buff.Bytes())
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func handleError(w http.ResponseWriter, message string, code int) {
	iHopeSo(tmpl.ExecuteTemplate(w, "error.html", ErrorPageData{
		Message: message,
		Code:    code,
	}))
}

func handleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "", http.StatusMethodNotAllowed)
		return
	}

	dto := CheckPasswordDto{
		Username: r.FormValue("username"),
		Password: r.FormValue("password"),
	}

	found, userId, err := tryFindUser(dto)
	if err != nil || !found {
		http.Error(w, "user not found", http.StatusUnauthorized)
		return
	}

	token, err := createToken(userId)
	if err != nil {
		http.Error(w, "could not create token", http.StatusInternalServerError)
		return
	}

	user, err := getUserById(userId)
	if err != nil {
		http.Error(w, "could not find user", http.StatusInternalServerError)
		return
	}

	resp := LoginResponse{
		Token:      token.Token,
		Expiration: token.Expiration,
		User:       user,
	}

	w.Header().Add("content-type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	err = json.NewEncoder(w).Encode(resp)
	if err != nil {
		log.Printf("failed to encode: %s", err)
	}
}
