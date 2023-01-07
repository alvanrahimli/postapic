package main

import (
	"fmt"
	"net/http"

	_ "github.com/mattn/go-sqlite3"
)

func main() {
	must(MakeOrIgnoreDir("images"))
	must(MakeOrIgnoreDir("db"))

	must(migrate())

	staticFilesFs := http.FileServer(http.Dir("static/"))
	imagesFs := http.FileServer(http.Dir("images/"))
	http.Handle("/static/", http.StripPrefix("/static/", staticFilesFs))
	http.Handle("/images/", http.StripPrefix("/images/", imagesFs))

	http.HandleFunc("/rss", handleRssFeed)
	http.HandleFunc("/postapic", handlePostAPic)
	http.HandleFunc("/api/posts", handleGetPostsApi)
	http.HandleFunc("/", handleGetPosts)

	fmt.Println("Listening at :8080")
	must(http.ListenAndServe(":8080", nil))
}
