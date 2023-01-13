# API Specifications

Poor man's swagger


## List posts

### Request

```http
GET /api/posts?offset=0&limit=10
```

### Response

```json
[
  {
    "id": 1,
    "title": "Post title",
    "image": {
      "url": "https://bit.ly/3Qzc8ah",
      "width": 1920,
      "height": 1080
    },
    "createdAt": "2023-01-13T14:31:53.316Z"
  }
]
```

## Login

### Request

```http
POST /api/login
Content-Type: application/x-www-form-urlencoded

username=Joe&password=WhosJoe
```

### Response

```json
{
  "token": "sdfkhdjkfhdsjdefinitelyranodomh",
  "user": {
    "id": 3,
    "userName": "Joe"
  }
}
```

## Upload

### Request

```http
POST /api/postapic
Authorization: Bearer sdfkhdjkfhdsjdefinitelyranodomh
Content-Type: multipart/form-data

title=such
picture=....
```
