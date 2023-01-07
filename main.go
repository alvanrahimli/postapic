package main

import (
	"fmt"
	"github.com/alvanrahimli/postapic/image"
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
	http.HandleFunc("/api/debug/set-size", func(w http.ResponseWriter, r *http.Request) {
		posts, err := getAllPosts(0, 100)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		for _, post := range posts {
			size := image.GetSize(post.Image.Url[1:])

			db := getDb()
			_, err := db.Exec("UPDATE posts SET image_width = ?, image_height = ? WHERE post_id = ?",
				size.Width, size.Height, post.PostId)

			must(err)
		}
	})
	http.HandleFunc("/", handleGetPosts)

	fmt.Println("Listening at :8080")
	must(http.ListenAndServe(":8080", nil))
}
