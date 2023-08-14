use base64::{
    alphabet,
    engine::{self, general_purpose},
    Engine as _,
};
use google_vision1::{
    api::{AnnotateImageRequest, Feature, ImageSource},
    Error, Result,
};
use google_vision1::{chrono, hyper, hyper_rustls, oauth2, FieldMask, Vision};
use http::response;
use hyper::{
    rt,
    service::{make_service_fn, service_fn},
    Body,
    Client,
    Request,
    Response,
    Server, // must use 'cargo add hyper --features full' in order get the Server struct
    Version,
};
use hyper_tls::HttpsConnector;
use serde::{Deserialize, Serialize};
use std::env;
use std::net::SocketAddr;
use std::{default::Default, future::Future};
use tokio::runtime::{Builder, Runtime};

fn auth_google_vision1() -> Result<Vision<hyper::client::HttpConnector, oauth2::InstalledFlow>> {
    // Get an ApplicationSecret instance by some means. It contains the `client_id` and
    // `client_secret`, among other things.
    let secret: oauth2::ApplicationSecret = Default::default();
    // Instantiate the authenticator. It will choose a suitable authentication flow for you,
    // unless you replace  `None` with the desired Flow.
    // Provide your own `AuthenticatorDelegate` to adjust the way it operates and get feedback about
    // what's going on. You probably want to bring in your own `TokenStorage` to persist tokens and
    // retrieve them from storage.
    let auth = oauth2::InstalledFlowAuthenticator::builder(
        secret,
        oauth2::InstalledFlowReturnMethod::HTTPRedirect,
    )
    .build()
    .await
    .unwrap();
    let mut hub = Vision::new(
        hyper::Client::builder().build(
            hyper_rustls::HttpsConnectorBuilder::new()
                .with_native_roots()
                .https_or_http()
                .enable_http1()
                .enable_http2()
                .build(),
        ),
        auth,
    );
    // You can configure optional parameters by calling the respective setters at will, and
    // execute the final call using `doit()`.
    // Values shown here are possibly random and not representative !
    let result = hub
        .operations()
        .list("name")
        .page_token("magna")
        .page_size(-11)
        .filter("ipsum")
        .doit()
        .await;

    match result {
        Err(e) => match e {
            // The Error enum provides details about what exactly happened.
            // You can also just use its `Debug`, `Display` or `Error` traits
            Error::HttpError(_)
            | Error::Io(_)
            | Error::MissingAPIKey
            | Error::MissingToken(_)
            | Error::Cancelled
            | Error::UploadSizeLimitExceeded(_, _)
            | Error::Failure(_)
            | Error::BadRequest(_)
            | Error::FieldClash(_)
            | Error::JsonDecodeError(_, _) => println!("{}", e),
        },
        Ok(res) => println!("Success: {:?}", res),
    }
}

fn get_port_from_command_line_argument(args: Vec<String>) -> u16 {
    // get port from command line argument
    for arg in args {
        if arg.starts_with("--port=") {
            let port_str = arg.split("=").nth(1).unwrap();
            let port = port_str.parse::<u16>().unwrap();
            return port;
        }
    }
    return 666; // default in case --port not found
}

async fn fn_handle_request(req: Request<Body>) -> Result<Response<Body>, hyper::Error> {
    println!("Received request: {:?}", req);

    // Extract auth token from headers (replace with actual extraction logic)
    let auth_token = extract_auth_token(req.headers());

    // Encode an example image (replace with your image encoding logic)
    let image_data = vec![0u8, 1u8, 2u8, 3u8]; // Replace with your image data
    let encoded_image = general_purpose::STANDARD.encode(&image_data);

    // Perform OCR or other processing with the auth token and encoded image

    // Return a response
    let response = format!(
        "Auth Token: {}\nEncoded Image: {}",
        auth_token, encoded_image
    );
    Ok(Response::new(Body::from(response)))
}
fn extract_auth_token(headers: &hyper::HeaderMap) -> String {
    // Replace with actual logic to extract auth token from headers
    // For example: headers.get("Authorization").unwrap().to_str().unwrap().to_string()
    "YOUR_AUTH_TOKEN".to_string()
}

#[derive(Debug, Serialize, Deserialize)]
struct Credentials {
    #[serde(rename = "type")]
    cred_type: String,
    project_id: String,
    private_key_id: String,
    private_key: String,
    client_email: String,
    client_id: String,
    auth_uri: String,
    token_uri: String,
    auth_provider_x509_cert_url: String,
    client_x509_cert_url: String,
}

async fn call_vision_api(
    image_data: Vec<u8>,
    token: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    // Create a hyper client
    let https = HttpsConnector::new();
    let client = Client::builder().build::<_, hyper::Body>(https);

    // Create a request to the Vision API
    let b64 = general_purpose::STANDARD.encode(&image_data);
    let request = Request::builder()
        .method("POST")
        .uri("https://vision.googleapis.com/v1/images:annotate")
        .header("Authorization", format!("Bearer {}", token))
        .header("Content-Type", "application/json")
        .body(Body::from(serde_json::to_string(&AnnotateImageRequest {
            image: Some(google_vision1::api::Image {
                content: Some(b64.as_bytes().to_vec()),
                source: None,
            }),
            features: todo!(),
            image_context: todo!(),
        })?))?;

    // Send the request and get the response
    let response = client.request(request).await?;

    // Read the response body as a string
    let body = hyper::body::to_bytes(response.into_body()).await?;
    let body_str = std::str::from_utf8(&body)?;

    // Return the response body as a string
    Ok(body_str.to_string())
}

fn do_vision(
    oauth2_token: &str,
    image_data: Vec<u8>,
) -> Result<String, Box<dyn std::error::Error>> {
    // Load the credentials from a file
    let credentials_file = std::fs::read_to_string("path/to/credentials.json").unwrap();
    let credentials: Credentials = serde_json::from_str(&credentials_file).unwrap();

    // Call the Vision API
    let response = call_vision_api(image_data, oauth2_token);

    return (response);
}

fn main() {
    let args: Vec<String> = env::args().collect();
    // get port from command line argument
    let port = get_port_from_command_line_argument(args);
    let addr = SocketAddr::from(([127, 0, 0, 1], port));

    // Create a hyper service
    let service = service_fn(|req: Request<Body>| async move {
        println!("Received request: {:?}", req);
        if req.version() == Version::HTTP_11 {
            // Extract auth token from headers (replace with actual extraction logic)
            let auth_token = extract_auth_token(req.headers());

            // Encode an image 
            let image_data = vec![0u8, 1u8, 2u8, 3u8]; // TODO: Not sure yet whether I'd want to deal with image here...
            let encoded_image = general_purpose::STANDARD.encode(&image_data);

            // Perform OCR or other processing with the auth token and encoded image

            // Return a response
            let response = format!(
                "Auth Token: {}\nEncoded Image: {}",
                auth_token, encoded_image
            );
            //Ok(Response::new(Body::from("Hello World")))
            Ok(Response::new(Body::from(response)))
        } else {
            // Note: it's usually better to return a Response with an appropriate StatusCode instead of an Err.
            Err("not HTTP/1.1, abort connection")
        }
    });
    let make_svc =
        make_service_fn(|_conn| async { Ok::<_, hyper::Error>(service_fn(fn_handle_request)) });

    // Create a hyper server
    let server = Server::bind(&addr).serve(make_svc);

    println!("Listening on http://{}", addr);

    // Run the server
    //let rt = Builder::new(  ).build().unwrap();
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(4)
        .thread_name("my-rust-app-thread")
        .build()
        .unwrap();
    rt.block_on(server).unwrap();
}
