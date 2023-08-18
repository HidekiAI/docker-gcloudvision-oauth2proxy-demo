use google_cloud::{datastore, pubsub, storage, vision};

#[cfg(test)]
mod tests {
    use super::*;
    use hyper::{Body, Request, StatusCode};

    #[tokio::test]
    async fn test_service_image() {
        let req = Request::builder()
            .method("POST")
            .uri("/")
            .header("content-type", "application/json")
            .body(Body::from("test"))
            .unwrap();

        let response = service_image(req).await.unwrap();
        assert_eq!(response.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn test_run() {
        run().await;
        // TODO: Add assertions for expected behavior
    }
}
