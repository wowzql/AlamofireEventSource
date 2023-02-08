# AlamofireEventSource

Alamofire plugin for Server-Sent Events (SSE).

## Usage | 使用

```swift
let endpoint = URL(string: "https://api.openai.com/v1/completions")!
let request = Session.default.eventSourceRequest(endpoint,method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers,  lastEventID: "0").responseEventSource { eventSource in
    switch eventSource.event {
    case .message(let message):
        print("Event source received message:", message)
        message.data
    case .complete(let completion):
        print("Event source completed:", completion)
    }
}
```

## Installation | 安装

Can be installed using SPM

```ruby
dependencies: [
    .package(url: "https://github.com/wowzql/AlamofireEventSource.git", .upToNextMajor(from: "1.1.0"))
]
```


## Todo list

Nothing!!

## Reference

- https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events
- https://developer.mozilla.org/en-US/docs/Web/API/EventSource
