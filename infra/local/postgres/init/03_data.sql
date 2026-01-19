INSERT INTO retail.customers
VALUES ('11111111-1111-1111-1111-111111111111', 'Alice Johnson', 'alice@test.com', 'US', now(), now()),
       ('22222222-2222-2222-2222-222222222222', 'Bob Smith', 'bob@test.com', 'CA', now(), now());
/* production info simulation */

INSERT INTO retail.products
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Wireless Mouse', 'Electronics', 29.90, true, now(), now()),
       ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Mechanical Keyboard', 'Electronics', 99.90, true, now(), now());

INSERT INTO retail.orders
VALUES ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', 'CREATED', 129.80, 'USD', now(),
        now());

INSERT INTO retail.order_items
VALUES (gen_random_uuid(), 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 29.90),
       (gen_random_uuid(), 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 1, 99.90);

INSERT INTO retail.payments
VALUES (gen_random_uuid(), 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'CREDIT_CARD', 'CAPTURED', 129.80, 'USD', now(),
        now());

INSERT INTO retail.shipments
VALUES (gen_random_uuid(), 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'SHIPPED', 'DHL', now(), NULL, now(), now());
