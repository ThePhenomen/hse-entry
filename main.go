package main

import (
	"database/sql"
	"flag"
	"fmt"
	"net/http"
	"os"

	_ "github.com/lib/pq"
)

var (
	host         string
	port         = 5432
	user         string
	password     string
	dbname       string
	i            = 0
	sqlStatement string
	nmb          = 0
	id           = 0
	db           *sql.DB
)

func init() {
	// Определение флагов для аргументов командной строки
	flag.StringVar(&host, "h", os.Getenv("POSTGRES_HOST"), "PostgreSQL user")
	flag.StringVar(&user, "U", os.Getenv("POSTGRES_USER"), "PostgreSQL user")
	flag.StringVar(&password, "P", os.Getenv("POSTGRES_PASSWORD"), "PostgreSQL password")
	flag.StringVar(&dbname, "d", os.Getenv("POSTGRES_DB"), "PostgreSQL database name")
}

func initDB() error {
	psqlInfo := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)
	var err error
	db, err = sql.Open("postgres", psqlInfo)
	if err != nil {
		return err
	}

	if err = db.Ping(); err != nil {
		return err
	}

	return nil
}

func handleRequest(w http.ResponseWriter, r *http.Request) {
	i++
	sqlStatement = `
 INSERT INTO mytbl (number)
 VALUES ($1)
 RETURNING id`
	err := db.QueryRow(sqlStatement, i).Scan(&id)
	if err != nil {
		panic(err)
	}

	sqlStatement = `SELECT number FROM mytbl WHERE id=$1`
	row := db.QueryRow(sqlStatement, id)
	err1 := row.Scan(&nmb)
	switch err1 {
	case sql.ErrNoRows:
		fmt.Println("No rows were returned!")
		return
	case nil:
		fmt.Println(nmb)
	default:
		panic(err1)
	}

	switch r.Method {
	case "GET":
		fmt.Fprintf(w, "Hello %d\n", nmb)
	default:
		fmt.Fprintf(w, "Sorry, only GET methods are supported.")
	}
}

func main() {

	flag.Parse()

	fmt.Println("Using the following parameters:")
	fmt.Printf("User: %s\nDatabase: %s\n", user, dbname)

	err := initDB()
	if err != nil {
		panic(err)
	}
	defer db.Close()

	http.HandleFunc("/", handleRequest)
	if err := http.ListenAndServe(":58080", nil); err != nil {
		panic(err)
	}
}
