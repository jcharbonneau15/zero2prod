use anyhow::Context;
use sqlx::PgPool;
use std::net::TcpListener;
use zero2prod::configuration::get_configuration;
use zero2prod::startup::run;
use zero2prod::telemetry::{get_subscriber, init_subscriber};

#[actix_rt::main]
async fn main() -> Result<(), anyhow::Error> {
    let subscriber = get_subscriber("zero2prod".into(), "info".into());
    init_subscriber(subscriber);

    // Panic if we can't read configuration
    let configuration = get_configuration().expect("Failed to read configuration");
    let connection = PgPool::connect(&configuration.database.conection_string())
        .await
        .map_err(anyhow::Error::from)
        .with_context(|| "Failed to connecto to Postgres")?;

    let address = format!("127.0.0.1:{}", configuration.application_port);

    let listener = TcpListener::bind(address)?;
    run(listener, connection)?.await?;
    Ok(())
}
