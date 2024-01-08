# TheLook source extract data model

The "TheLook" source extract data sets data model.

This model was generating using the Chat prompt
```
create a PlantUML diagram for a data model using ER notation that includes the following objects
* orders
* order_items
* users
* products
* distribution_centers
* inventory_items
```

```plantuml
@startuml

entity "orders" as orders {
    + order_id [PK]
    --
    customer_id [FK]
    order_date
    total_amount
}

entity "order_items" as order_items {
    + order_item_id [PK]
    --
    order_id [FK]
    product_id [FK]
    quantity
    price
}

entity "users" as users {
    + user_id [PK]
    --
    username
    email
    address
}

entity "products" as products {
    + product_id [PK]
    --
    product_name
    category
    price
}

entity "distribution_centers" as distribution_centers {
    + center_id [PK]
    --
    center_name
    location
}

entity "inventory_items" as inventory_items {
    + item_id [PK]
    --
    product_id [FK]
    center_id [FK]
    quantity
}

orders ||--o{ order_items
users ||--o{ orders
products ||--o{ order_items
distribution_centers ||--o{ inventory_items
products ||--o{ inventory_items

@enduml

```

## Target data model
The target data model created by updating the draft response code above for `orders`, `order_items`, and `users`.
This model focuses on the primary keys [PK] and foreign key [FK] fields and additional attributes are excluded
in order to focus on the overall data relationships.

```plantuml
@startuml

entity "orders" as orders {
    + order_id [PK]
    --
    user_id [FK]
}

entity "order_items" as order_items {
    + id [PK]
    --
    order_id [FK]
    user_id [FK]
    product_id [FK]
    inventory_id [FK]
}

entity "users" as users {
    + id [PK]
}

users ||--o{ orders : has
orders ||--o{ order_items : contains
users ||--o{ order_items : has
@enduml

```