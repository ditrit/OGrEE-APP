package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"ogree_app_backend/auth"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"text/template"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
)

var tmplt *template.Template

func init() {
	err := godotenv.Load(".env")
	if err != nil {
		panic("Error loading .env file")
	}
	// hashedPassword, _ := bcrypt.GenerateFromPassword(
	// 	[]byte("password"), bcrypt.DefaultCost)
	// println(string(hashedPassword))
	tmplt = template.Must(template.ParseFiles("docker-env-template.txt"))
}

func main() {
	port := flag.Int("port", 8082, "an int")
	flag.Parse()
	router := gin.Default()
	corsConfig := cors.DefaultConfig()
	corsConfig.AllowAllOrigins = true
	corsConfig.AllowHeaders = []string{"X-Requested-With", "Content-Type", "Authorization", "Origin", "Accept"}
	router.Use(cors.New(corsConfig))

	router.POST("/api/login", login) // public endpoint

	router.Use(auth.JwtAuthMiddleware()) // protected
	router.GET("/api/tenants", getTenants)
	router.GET("/api/tenants/:name", getTenantDockerInfo)
	router.DELETE("/api/tenants/:name", removeTenant)
	router.POST("/api/tenants", addTenant)
	router.GET("/api/containers/:name", getContainerLogs)

	router.Run(":" + strconv.Itoa(*port))
}

type tenant struct {
	Name             string `json:"name" binding:"required"`
	CustomerPassword string `json:"customerPassword"`
	ApiUrl           string `json:"apiUrl"`
	WebUrl           string `json:"webUrl"`
	ApiPort          string `json:"apiPort"`
	WebPort          string `json:"webPort"`
}

type container struct {
	Name       string `json:"Names"`
	RunningFor string `json:"RunningFor"`
	State      string `json:"State"`
	Image      string `json:"Image"`
	Size       string `json:"Size"`
	Ports      string `json:"Ports"`
}

type user struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
	Token    string `json:"token"`
}

func getTenants(c *gin.Context) {
	data, e := ioutil.ReadFile("tenants.json")
	if e != nil {
		panic(e.Error())
	}
	var listTenants []tenant
	json.Unmarshal(data, &listTenants)
	fmt.Println(listTenants)
	response := make(map[string][]tenant)
	response["tenants"] = listTenants
	c.IndentedJSON(http.StatusOK, response)
}

func getTenantDockerInfo(c *gin.Context) {
	name := c.Param("name")
	println(name)
	cmd := exec.Command("docker", "ps", "--all", "--format", "\"{{json .}}\"")
	cmd.Dir = "docker/"
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if output, err := cmd.Output(); err != nil {
		fmt.Println(fmt.Sprint(err) + ": " + stderr.String())
		c.IndentedJSON(http.StatusInternalServerError, stderr.String())
		return
	} else {
		response := []container{}
		s := bufio.NewScanner(bytes.NewReader(output))
		for s.Scan() {
			var dc container
			jsonOutput := s.Text()
			jsonOutput, _ = strings.CutPrefix(jsonOutput, "\"")
			jsonOutput, _ = strings.CutSuffix(jsonOutput, "\"")
			fmt.Println(jsonOutput)
			if err := json.Unmarshal([]byte(jsonOutput), &dc); err != nil {
				//handle error
				fmt.Println(err.Error())
			}
			fmt.Println(dc)
			if strings.Contains(dc.Name, name) {
				response = append(response, dc)
			}
		}
		if s.Err() != nil {
			// handle scan error
			fmt.Println(s.Err().Error())
		}

		c.IndentedJSON(http.StatusOK, response)
	}
}

func getContainerLogs(c *gin.Context) {
	name := c.Param("name")
	println(name)
	cmd := exec.Command("docker", "logs", name, "--tail", "1000")
	cmd.Dir = "docker/"
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if output, err := cmd.Output(); err != nil {
		fmt.Println(fmt.Sprint(err) + ": " + stderr.String())
		c.IndentedJSON(http.StatusInternalServerError, stderr.String())
		return
	} else {
		response := map[string]string{}
		response["logs"] = string(output)

		c.IndentedJSON(http.StatusOK, response)
	}
}

func addTenant(c *gin.Context) {
	data, e := ioutil.ReadFile("tenants.json")
	if e != nil {
		panic(e.Error())
	}
	var listTenants []tenant
	json.Unmarshal(data, &listTenants)

	// Call BindJSON to bind the received JSON
	var newTenant tenant
	if err := c.BindJSON(&newTenant); err != nil {
		c.IndentedJSON(http.StatusBadRequest, err.Error())
		return
	} else {
		// Create .env file
		file, _ := os.Create("docker/.env")
		err = tmplt.Execute(file, newTenant)
		if err != nil {
			panic(err)
		}
		file.Close()

		// Docker compose up
		cmd := exec.Command("docker-compose", "-p", strings.ToLower(newTenant.Name), "up", "-d")
		cmd.Dir = "docker/"
		var stderr bytes.Buffer
		cmd.Stderr = &stderr
		if _, err := cmd.Output(); err != nil {
			fmt.Println(fmt.Sprint(err) + ": " + stderr.String())
			c.IndentedJSON(http.StatusInternalServerError, stderr.String())
			return
		}

		// Add to local json
		listTenants = append(listTenants, newTenant)
		data, _ := json.MarshalIndent(listTenants, "", "  ")
		_ = ioutil.WriteFile("tenants.json", data, 0644)
		c.IndentedJSON(http.StatusOK, "all good")
	}

}

func removeTenant(c *gin.Context) {
	tenantName := c.Param("name")

	for _, str := range []string{"_cli", "_webapp", "_api", "_db"} {
		cmd := exec.Command("docker", "rm", "--force", strings.ToLower(tenantName)+str)
		cmd.Dir = "docker/"
		var stderr bytes.Buffer
		cmd.Stderr = &stderr
		if _, err := cmd.Output(); err != nil {
			fmt.Println(fmt.Sprint(err) + ": " + stderr.String())
			c.IndentedJSON(http.StatusInternalServerError, stderr.String())
			return
		}
	}

	// Update local file
	data, e := ioutil.ReadFile("tenants.json")
	if e != nil {
		panic(e.Error())
	}
	var listTenants []tenant
	json.Unmarshal(data, &listTenants)
	for i, ten := range listTenants {
		if ten.Name == tenantName {
			listTenants = append(listTenants[:i], listTenants[i+1:]...)
		}
	}
	data, _ = json.MarshalIndent(listTenants, "", "  ")
	_ = ioutil.WriteFile("tenants.json", data, 0644)
	c.IndentedJSON(http.StatusOK, "all good")
}

func login(c *gin.Context) {
	var userIn user
	if err := c.BindJSON(&userIn); err != nil {
		c.IndentedJSON(http.StatusBadRequest, err.Error())
	} else {
		// Check credentials
		if userIn.Email != "admin" ||
			bcrypt.CompareHashAndPassword([]byte(os.Getenv("ADM_PASSWORD")), []byte(userIn.Password)) != nil {
			c.IndentedJSON(http.StatusBadRequest, gin.H{"error": "Invalid credentials"})
			return
		}

		// Generate token
		token, err := auth.GenerateToken(userIn.Email)
		if err != nil {
			c.String(http.StatusInternalServerError, err.Error())
			return
		}

		// Respond
		response := make(map[string]map[string]string)
		response["account"] = make(map[string]string)
		response["account"]["Email"] = userIn.Email
		response["account"]["token"] = token
		response["account"]["isTenant"] = "true"
		c.IndentedJSON(http.StatusOK, response)
	}
}
