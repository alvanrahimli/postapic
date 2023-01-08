package main

import (
	"errors"
	"log"
	"math/rand"
	"os"
	"time"
)

func MakeOrIgnoreDir(dir string) error {
	_, err := os.Stat(dir)
	if errors.Is(err, os.ErrNotExist) {
		err = os.Mkdir(dir, os.ModePerm)
		if err != nil {
			return err
		}
	}

	return err
}

var letters = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func RandSeq(n int) string {
	// TODO: Use crypto/rand for more secure codes
	rand.Seed(time.Now().UnixNano())
	b := make([]rune, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}

	return string(b)
}

func must(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func iHopeSo(err error) {
	if err != nil {
		log.Println(err.Error())
	}
}
