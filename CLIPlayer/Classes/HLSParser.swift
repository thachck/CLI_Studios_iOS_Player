import Foundation

struct CustomError: Error {
  let message: String

  init(_ message: String) {
    self.message = message
  }

  public var localizedDescription: String {
    return message
  }
}

public struct HLSStreamInfo {
  var width: Int?
  var height: Int?
  var url: URL?
  var averageBandwidth: Int?
  var bandwidth: Int?
  var frameRate: Float?
  var codecs: String?
}

public struct HLSParser {

  public typealias success = (_ parsedResponse:[HLSStreamInfo]) -> Void
  public typealias failed = (_ error:Error?) -> Void

  public init() {}

  public func parseStreamTags(url: URL,successBlock: @escaping success, failedBlock:@escaping failed) {
    var request = URLRequest(url: url)
    request.httpMethod = "Get"
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      guard let data = data, error == nil else {
        print("error=\(String(describing: error))")
        failedBlock(error)
        return
      }
      if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
        print("statusCode should be 200, but is \(httpStatus.statusCode)")
        print("response = \(String(describing: response))")
      }

      guard let responseString = String(data: data, encoding: .utf8) else {
        failedBlock(CustomError("Invalid response string"))
        return
      }

      let items = responseString.components(separatedBy: "#EXT-X-STREAM-INF").dropFirst()
      let hlsStreamInfos = items.map { item -> HLSStreamInfo in
        var hlsStreamInfo = HLSStreamInfo()
        let components = item.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
        if components.count != 2 {
          return hlsStreamInfo
        }
        hlsStreamInfo.url = url.deletingLastPathComponent().appendingPathComponent(components[1])
        let info = components[0]

        hlsStreamInfo.bandwidth = match(str: info, regex: #"(?::|.+,)BANDWIDTH=(\d+)"#) {
          $0.count == 2 ? Int($0[1]) : nil
        } as? Int

        hlsStreamInfo.averageBandwidth = match(str: info, regex: #"(?::|.+,)AVERAGE-BANDWIDTH=(\d+)"#) {
          $0.count == 2 ? Int($0[1]) : nil
        } as? Int

        hlsStreamInfo.frameRate = match(str: info, regex: #"(?::|.+,)FRAME-RATE=([\d|\.]+)"#) {
          $0.count == 2 ? Float($0[1]) : nil
        } as? Float

        hlsStreamInfo.codecs = match(str: info, regex: #"(?::|.+,)CODECS="(.+)""#) {
          $0.count == 2 ? $0[1] : nil
        } as? String

        (hlsStreamInfo.width, hlsStreamInfo.height) = match(str: info, regex: #"(?::|.+,)RESOLUTION=(\d+)x(\d+)"#) {
          $0.count == 3 ? (Int($0[1]), Int($0[2])) : (nil, nil)
        } as? (Int?, Int?) ?? (nil, nil)

        return hlsStreamInfo
      }

      successBlock(hlsStreamInfos)
    }

    task.resume()
  }

  private func match(str: String, regex: String, transform: ([String]) -> Any?) -> Any? {
    let nsString = str as NSString
    let matches = (try? NSRegularExpression(pattern: regex, options:.allowCommentsAndWhitespace))?.matches(in: str, options: [], range: NSMakeRange(0, str.count)).map { match in
      (0..<match.numberOfRanges).map { match.range(at: $0).location == NSNotFound ? "" : nsString.substring(with: match.range(at: $0)) }
    } ?? []
    return transform(matches.flatMap { $0 })
  }
}
