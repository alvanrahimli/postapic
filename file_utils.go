package main

import (
	"errors"
	"log"
	"os"
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
