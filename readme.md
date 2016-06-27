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

3. Adjust inventory for a given product, at a given product size:

```
PUT /:product_sku

# Request payload
{
    "size": "size_1",
    "amount": -2
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

## Using the API

Start the API:

```
ruby app.rb
```

Note: The following examples are idealized. They are the desired responses,
not the actual responses.

Create inventory:

```
curl -X PUT -d 'inventory[size_1]=10&inventory[size_2]=20' localhost:2000/abc123

{
    "data": {
        "id": "abc123",
        "inventory": {
            "size_1": 10,
            "size_2": 20
        }
    }
}
```

Read inventory

```
curl localhost:2000/abc123

{
    "data": {
        "id": "abc123",
        "inventory": {
            "size_1": 10,
            "size_2": 20
        }
    }
}
```

Adjust inventory

```
curl -X PUT -d 'size=size_1&amount=-2' localhost:2000/abc123

{
    "data": {
        "id": "abc123",
        "inventory": {
            "size_1": 8,
            "size_2": 20
        }
    }
}
```

## Circuit Breaker

The integration of the microservice API with it's data store is fortified with
a Circuit Breaker pattern. If the data store fails 3 times consecutively,
it will go into a "red light", or "broken circuit" state. Successive calls to
the API will not be routed to the data store until a "cool off" period has
elapsed. The cool off period is configured for 10 seconds.

The circuit breaker can be tested by shutting down Couchdb and running the
following command more than three times:

```
curl -X PUT -d 'inventory[size_1]=10' localhost:2000/abc123
```

The output will show a `Errno::ECONNREFUSED` error for the first three
iterations, then it will show a `Stoplight::Error::RedLight` after that.

After waiting 10 seconds and turning Couchdb back on, the API will work
without failure.

## Unfinished Implementation

1. The web endpoint was added hastily, without tests. Under normal circumstances,
  it would be developed in a Test-Driven manner.
2. The endpoint responses currently do not reflect a clean, consistent API.
3. Deployment tooling. Tooling needs to be created or integrated to deploy the
  microservice.
4. Input validation and input cleanup needs to be added to the service object.
5. Authentication should be added to the endpoint to ensure the microservice
  is only accessed by internal services.

## Scaling

A microservices architecture is a type of Functional Decomposition scaling
strategy, or splitting an application into different things to scale it. If
done correctly, this kind of decomposition can lead to an easy
Horizontal Duplication scaling strategy, or cloning a component
so that multiple requests of a type can be handled in parallel.

When a request-handling component is cloned, it usually needs a load balancer
to balance multiple requests among the components. For example, this inventory
management microservice might use the reverse proxy features of Nginx to
distribute requests among multiple instances of the microservice.

As the microservice scales up, instances may fill up a computing node in a
cloud, and the node may have a single Nginx instance distributing the requests.
When the node reaches a threshold capacity, a second node can be added with
the same configuration as the first, and both nodes can be put behind a
high-volume load balancer. This node cloning can continue until the high-volume
load balancer reaches capacity.

For the microservice's data store, both Couchdb and Cassandra are designed to
scale horizontally well too. The data store can either live on the same node
as the endpoint or it can live on separate nodes.
