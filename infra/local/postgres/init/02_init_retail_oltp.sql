CREATE SCHEMA IF NOT EXISTS retail;
SET search_path TO retail;

CREATE TABLE customers
(
    customer_id UUID PRIMARY KEY,
    full_name   TEXT        NOT NULL,
    email       TEXT UNIQUE NOT NULL,
    country     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE products
(
    product_id   UUID PRIMARY KEY,
    product_name TEXT           NOT NULL,
    category     TEXT,
    price        NUMERIC(10, 2) NOT NULL,
    active       BOOLEAN        NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE TABLE orders
(
    order_id     UUID PRIMARY KEY,
    customer_id  UUID           NOT NULL REFERENCES customers (customer_id),
    order_status TEXT           NOT NULL,
    order_total  NUMERIC(10, 2) NOT NULL,
    currency     TEXT           NOT NULL,
    created_at   TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE TABLE order_items
(
    order_item_id UUID PRIMARY KEY,
    order_id      UUID           NOT NULL REFERENCES orders (order_id),
    product_id    UUID           NOT NULL REFERENCES products (product_id),
    quantity      INT            NOT NULL,
    unit_price    NUMERIC(10, 2) NOT NULL
);

CREATE TABLE payments
(
    payment_id     UUID PRIMARY KEY,
    order_id       UUID           NOT NULL REFERENCES orders (order_id),
    payment_method TEXT           NOT NULL,
    payment_status TEXT           NOT NULL,
    amount         NUMERIC(10, 2) NOT NULL,
    currency       TEXT           NOT NULL,
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE TABLE shipments
(
    shipment_id     UUID PRIMARY KEY,
    order_id        UUID        NOT NULL REFERENCES orders (order_id),
    shipment_status TEXT        NOT NULL,
    carrier         TEXT,
    shipped_at      TIMESTAMPTZ,
    delivered_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
