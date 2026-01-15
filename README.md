# retail-data-pipeline

``````
            ┌──────────────┐
            │ Batch Source │
            │ (JSON / API) │
            └──────┬───────┘
                   |
            Python Extract
                   |
                   v
┌──────────────┐   Airflow   ┌──────────────┐
│ Kafka        │────────────▶│ Snowflake    │
│ (Events)     │             │ Bronze       │
└──────┬───────┘             │ (Raw Events) │
       |                     └──────┬───────┘
   Kafka Consumer                    |
                                     v
                               dbt (Silver)
                                     |
                                     v
                               dbt (Gold)
                                     |
                                     v
                                  Power BI
``````


ola
