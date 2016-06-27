# Inventory Management Microservice

This microservice consists of a REST API, backed by a Couchdb data store
(external dependency).

## API

The API provides the following three actions:

1. Get inventory amounts for product, grouped by product size:

```
GET /:product_sku

# Response payload
{
    "data": {
        "_id": "abc123",
        "inventory": {
            "size_1": 3,
            "size_2": 0,
            "size_3": 1
        }
    }
}
```

2. Set inventory amounts for a given product, grouped by product size:

```
PUT /:product_sku

# Request payload
{
    "inventory": {
        "size_1": 20,
        "size_2": 10,
        "size_3": 15
    }
}

# Response payload
{
    "data": {
        "_id": "abc123",
        "inventory": {
            "size_1": 20,
            "size_2": 10,
            "size_3": 15
        }
    }
}
```

3. Use inventory for a given product, at a given product size:

```
PUT /:product_sku

# Request payload
{
    "size": "size_1",
    "amount": 2
}

# Response payload
{
    "data": {
        "_id": "abc123",
        "inventory": {
            "size_1": 18,
            "size_2": 10,
            "size_3": 15
        }
    }
}
```

## Testing

The test suite for the microservice can be run with the following command:

```
rake
```

Individual test files can be run with:

```
rake test TEST=test/test_foobar.rb"
```

Individual tests can be run with:

```
rake test TEST=test/test_foobar.rb TESTOPTS="--name=test_foobar1"
```
