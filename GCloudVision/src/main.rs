use base64::{engine::general_purpose, Engine as _};

//use google_vision1::{
//    api::{AnnotateImageRequest, Feature, ImageSource},
//    chrono, hyper, hyper_rustls, oauth2, Error, FieldMask, Result, Vision,
//};
use http::{Request, Response, StatusCode};
use hyper::{
    service::service_fn,
    Body,
    Client, // must use 'cargo add hyper --features full' in order get the Server struct
    Version,
};

use serde::{Deserialize, Serialize};

use std::{env, net::SocketAddr};

const PROJECT_ID: &str = "my_rust_app";

fn get_port_from_command_line_argument(args: Vec<String>) -> u16 {
    // get port from command line argument
    for arg in args {
        if arg.starts_with("--port=") {
            let port_str = arg.split("=").nth(1).unwrap();
            let port = port_str.parse::<u16>().unwrap();
            return port;
        } else if arg.starts_with("-p") {
            let port = arg.split("-p").nth(1).unwrap();
            return port.parse::<u16>().unwrap();
        }
    }
    println!("Usage: cargo run -- --port=666");
    std::process::exit(0); // exit the entire application

    //return 0; // 0 usually means ANY_PORT (at least for C/C++ BSD sockets impl)
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
        "[{}] Auth Token: {}\nEncoded Image: {}",
        PROJECT_ID, auth_token, encoded_image
    );
    Ok(Response::new(Body::from(response)))
}
fn extract_auth_token(_headers: &hyper::HeaderMap) -> String {
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
    auth_token: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    let b64 = general_purpose::STANDARD.encode(&image_data);

    // Create a request to the Vision API
    let client: Client<hyper::client::HttpConnector> = Client::new();
    // build request to be sent to the Vision API
    let request_vision_api: Request<Body> = Request::builder()
        .method("POST")
        .uri("https://vision.googleapis.com/v1/images:annotate")
        .header("content-type", "application/json")
        .header("Authorization", format!("Bearer {}", auth_token))
        .body(Body::from(format!(
            "{{\"requests\":[{{\"image\":{{\"content\":\"{}\"}},\"features\":[{{\"type\":\"TEXT_DETECTION\"}}]}}]}}",
            b64
        )))
        .unwrap();

    // Send the request and get the response
    let response: Response<Body> = client.request(request_vision_api).await?;

    // Read the response body as a string
    let body = hyper::body::to_bytes(response.into_body()).await?;
    let body_str = std::str::from_utf8(&body)?;

    // Return the response body as a string
    Ok(body_str.to_string())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    // get port from command line argument
    let port = get_port_from_command_line_argument(args);
    // listen to port 666 for HTTP/1.1 requests (requires sudo privileges to bind to listener port)
    let listen_address_ipv4 = SocketAddr::from(([127, 0, 0, 1], port)); // NOTE: assumes IPv4 address for now
    println!("Listening on http://{}", listen_address_ipv4);

    // Create a hyper service that listens for HTTP/1.1 requests
    {
        use hyper::service::{make_service_fn, service_fn};
        use hyper::{Body, Error, Response, Server};
        let my_make_service =
            make_service_fn(|_addr_Stream: &hyper::server::conn::AddrStream| async {
                Ok::<_, Error>(service_fn(|req_body: Request<Body>| async {
                    let req: Request<Body> = Request::builder()
                        .method(req_body.method().clone())
                        .uri(req_body.uri().clone())
                        .body(req_body.into_body())
                        .unwrap();

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
                            "[{}] Auth Token: {}\nEncoded Image: {}",
                            PROJECT_ID, auth_token, encoded_image
                        );
                        //Ok(Response::new(Body::from("ERROR: my_rust_app")))
                        Ok(Response::new(Body::from(response)))
                    } else {
                        // Note: it's usually better to return a Response with an appropriate StatusCode instead of an Err.
                        Err("not HTTP/1.1, abort connection")
                    }
                }))
            });
        // Create a hyper server
        //let my_server1 = Server::bind(&listen_address_ipv4).serve(my_make_service);
        let my_service_test = service_fn(|req: Request<Body>| async move {
            println!("Received request: {:?}", req);
            if req.version() == Version::HTTP_11 && req.uri().path() == "/oauth2/callback" {
                // The URI is structured as follows:
                //
                // ```
                // abc://username:password@example.com:123/path/data?key=value&key2=value2#fragid1
                // |-|   |-------------------------------||--------| |-------------------| |-----|
                //  |                  |                       |               |              |
                // scheme          authority                 path            query         fragment
                // ```
                // Extract query parameters from the request URI
                let query_params = req.uri().query().unwrap_or("");
                let query_pairs = form_urlencoded::parse(query_params.as_bytes());

                // Print out the query parameters
                for (key, value) in query_pairs {
                    println!("{}: {}", key, value);
                }

                // Return a response with a 200 OK status code
                let response: Response<Body> = Response::builder()
                    .status(StatusCode::OK)
                    .body(Body::from("Received query parameters"))
                    .unwrap();
                hyper::Result::Ok(response)
            } else {
                // Return a response with a 404 Not Found status code
                let response: Response<Body> = Response::builder()
                    .status(StatusCode::NOT_FOUND)
                    .body(Body::from("Not found"))
                    .unwrap();
                hyper::Result::Ok(response)
            }
        });
    }

    let _service_image = service_fn(|req: Request<Body>| async move {
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
                "[{}] Auth Token: {}\nEncoded Image: {}",
                PROJECT_ID, auth_token, encoded_image
            );
            //Ok(Response::new(Body::from("ERROR: my_rust_app")))
            Ok(Response::new(Body::from(response)))
        } else {
            // Note: it's usually better to return a Response with an appropriate StatusCode instead of an Err.
            Err(format!("[{}] not HTTP/1.1, abort connection", PROJECT_ID))
        }
    });

    //#[cfg(feature = "tcp")]
    async fn fn_future_async_run(listen_address_ipv4: &SocketAddr) {
        use hyper::service::{make_service_fn, service_fn};
        use hyper::{Body, Response, Server};

        let make_service =
            make_service_fn(|_addr_Stream: &hyper::server::conn::AddrStream| async {
                Ok::<_, hyper::Error>(service_fn(|req_body: Request<Body>| async {
                    let req: Request<Body> = Request::builder()
                        .method(req_body.method().clone())
                        .uri(req_body.uri().clone())
                        .body(req_body.into_body())
                        .unwrap();

                    let http_version = req.version();
                    let _http_method = req.method().clone();
                    let http_uri = req.uri().clone();
                    let _http_body = req.body().clone();
                    let _http_headers = req.headers().clone();
                    // The URI is structured as follows:
                    //
                    // ```
                    // abc://username:password@example.com:123/path/data?key=value&key2=value2#fragid1
                    // |-|   |-------------------------------||--------| |-------------------| |-----|
                    //  |                  |                       |               |              |
                    // scheme          authority                 path            query         fragment
                    // ```
                    // Extract query parameters from the request URI
                    let query_params = http_uri.query().unwrap_or("");
                    let query_pairs = form_urlencoded::parse(query_params.as_bytes());
                    // Print out the query parameters
                    println!("[{}] Received request: {:?}", PROJECT_ID, req);
                    println!("Received query parameters: ");
                    for (key, value) in query_pairs {
                        println!("{}: {}", key, value);
                    }
                    match http_version == Version::HTTP_11 {
                        true => {
                            match http_uri.path() {
                                "/oauth2/callback" => {
                                    // Since we're persisting both username and auth-token in redis,
                                    // we really don't need to do anything here as long as
                                    // the U.I./view side is able to always know the username.
                                    // Based on the username, we can internally in this app,
                                    // query redis to get the auth-token.
                                    let response = hyper::Response::builder()
                                        .status(StatusCode::OK)
                                        .body(Body::from(
                                            "place holder to request at '/oauth2/callback' path",
                                        ))
                                        .unwrap();
                                    let ret_response: Result<Response<Body>, &str> = Ok(response);
                                    ret_response
                                },
                                "/image" => {
                                    // Return a response with a 200 OK status code
                                    let response = hyper::Response::builder()
                                        .status(StatusCode::OK)
                                        .body(Body::from(
                                            "place holder to request at '/image' path",
                                        ))
                                        .unwrap();
                                    let ret_response: Result<Response<Body>, &str> = Ok(response);
                                    ret_response
                                },
                                "/" => {
                                    // Return a response with a 200 OK status code
                                    let response = hyper::Response::builder()
                                        .status(StatusCode::OK)
                                        .body(Body::from(
                                            "place holder to request at '/' path",
                                        ))
                                        .unwrap();
                                    let ret_response: Result<Response<Body>, &str> = Ok(response);
                                    ret_response
                                },
                                _ => {
                                    // default routing path
                                    let response = hyper::Response::builder()
                                        .status(StatusCode::FORBIDDEN)
                                        .body(Body::from(format!(
                                            "[{}] Unhandled routing path '{}'",
                                            PROJECT_ID,
                                            http_uri.path()
                                        )))
                                        .unwrap();
                                    let ret_response: Result<Response<Body>, &str> = Ok(response);
                                    ret_response
                                }
                            }
                        }
                        _ => {
                            let response = hyper::Response::builder()
                                .status(StatusCode::HTTP_VERSION_NOT_SUPPORTED)
                                .body(Body::from(
                                    StatusCode::HTTP_VERSION_NOT_SUPPORTED
                                        .canonical_reason()
                                        .unwrap(),
                                ))
                                .unwrap();
                            let ret_response: Result<Response<Body>, &str> = Ok(response);
                            ret_response
                        }
                    }
                }))
            });
        // listen to port 666 for HTTP/1.1 requests (requires sudo privileges to bind to listener port)
        let server = Server::bind(&listen_address_ipv4).serve(make_service);

        // Prepare some signal for when the server should start shutting down...
        let (tx, rx) = tokio::sync::oneshot::channel::<()>();
        let graceful = server.with_graceful_shutdown(async {
            rx.await.ok();
        });

        // Await the `server` receiving the signal...
        if let Err(e) = graceful.await {
            eprintln!("[my-rust-app] server error: {}", e);
        }

        // And later, trigger the signal by calling `tx.send(())`.
        let _ = tx.send(());
    }

    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(4)
        .thread_name("my-rust-app-thread")
        .enable_io() // for now, just enable all I/O
        .build()
        .unwrap();
    rt.block_on(fn_future_async_run(&listen_address_ipv4.clone()));
}
