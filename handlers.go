package main

import (
	"bytes"
	"html/template"
	"log"
	"net/http"
	"strconv"
	"strings"

	"github.com/alvanrahimli/postapic/image"
)

var tmpl = template.Must(template.ParseGlob("templates/*"))
var imgMgr = image.Manager{
	Directory: "images",
	MaxWidth:  1777,
	MaxHeight: 1000,
}

const MaxUploadBufferSize = 1 << 20 // 1 MiB
const MaxFileSize = 20 << 20        // 20 MiB

func handlePostAPic(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		var users []UserDto
		var err error
		users, err = getAllUsers()
		if err != nil {
			log.Printf("could not get users. err: %s\n", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		iHopeSo(tmpl.ExecuteTemplate(w, "postapic.html", SubmitPageData{Users: users}))

	case "POST":
		r.ParseMultipartForm(MaxUploadBufferSize)

		picture, pictureHeader, err := r.FormFile("picture")
		if err != nil {
			log.Printf("Could not get form file. err: %s\n", err.Error())
			http.Redirect(w, r, "/", http.StatusFound)
			return
		}
		if pictureHeader.Size > MaxFileSize {
			log.Printf("Max file upload size exceeded (size: %v)\n", pictureHeader.Size)
			http.Redirect(w, r, "/postapic", http.StatusFound)
			return
		}
		defer picture.Close()

		userId, err := strconv.Atoi(r.FormValue("user_id"))
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		userPwdDto := UserPasswordDto{
			UserId:   userId,
			Password: r.FormValue("password"),
		}
		title := strings.TrimSpace(r.FormValue("title"))

		userExists, userId, err := checkUserPassword(userPwdDto)
		if !userExists {
			http.Redirect(w, r, "/", http.StatusFound)
			return
		} else if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		imageKey, err := imgMgr.Upload(picture)
		if err != nil {
			log.Println("error creating file", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		err = createPost(PostCreateDto{
			Title:    title,
			UserId:   userId,
			ImageKey: imageKey,
		})
		if err != nil {
			log.Printf("could not insert post. err: %s\n", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		http.Redirect(w, r, "/", http.StatusFound)
	}
}

func handleGetPosts(w http.ResponseWriter, _ *http.Request) {
	posts, err := getAllPosts()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	iHopeSo(tmpl.ExecuteTemplate(w, "postlist.html", PostsPageData{Posts: posts}))
}

func handleRssFeed(w http.ResponseWriter, _ *http.Request) {
	posts, err := getAllPosts()
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