// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@testable import A2UISwiftCore
import Testing
import Foundation

@Suite("JsonBlockParser")
struct JsonBlockParserTests {

  // MARK: - stripJsonBlock: should NOT eat balanced brackets that aren't JSON

  @Test("stripJsonBlock preserves markdown link labels `[label](url)`")
  func stripJsonBlock_preservesMarkdownLinkLabel() {
    let input = "詳しくはこちら [NNN NEWS ZIP（YouTube）](https://www.youtube.com/watch?v=x)"
    #expect(JsonBlockParser.stripJsonBlock(input) == input)
  }

  @Test("stripJsonBlock preserves multiple markdown link labels in one line")
  func stripJsonBlock_preservesMultipleMarkdownLinks() {
    let input = "[A](https://a.example.com) / [B](https://b.example.com)"
    #expect(JsonBlockParser.stripJsonBlock(input) == input)
  }

  @Test("stripJsonBlock preserves balanced `(...)` and `[...]` in prose")
  func stripJsonBlock_preservesProseBrackets() {
    let input = "see [section 1] for details (note: read carefully)"
    #expect(JsonBlockParser.stripJsonBlock(input) == input)
  }

  @Test("stripJsonBlock preserves curly braces in prose `{example}`")
  func stripJsonBlock_preservesCurlyBracesInProse() {
    // `{example}` is balanced but is not JSON. It should be preserved.
    let input = "use the {example} placeholder"
    #expect(JsonBlockParser.stripJsonBlock(input) == input)
  }

  // MARK: - stripJsonBlock: should still strip real JSON

  @Test("stripJsonBlock strips a bare JSON object")
  func stripJsonBlock_stripsBareJsonObject() {
    let input = "prefix {\"key\":\"value\"} suffix"
    let out = JsonBlockParser.stripJsonBlock(input)
    #expect(out == "prefix  suffix")
  }

  @Test("stripJsonBlock strips a bare JSON array")
  func stripJsonBlock_stripsBareJsonArray() {
    let input = "prefix [{\"component\":\"weather\"}] suffix"
    let out = JsonBlockParser.stripJsonBlock(input)
    #expect(out == "prefix  suffix")
  }

  @Test("stripJsonBlock strips a fenced JSON code block")
  func stripJsonBlock_stripsFencedJsonBlock() {
    let input = """
      hello
      ```json
      {"a":1}
      ```
      world
      """
    let out = JsonBlockParser.stripJsonBlock(input)
    #expect(!out.contains("```"))
    #expect(!out.contains("\"a\""))
    #expect(out.contains("hello"))
    #expect(out.contains("world"))
  }

  @Test("stripJsonBlock strips JSON but keeps prose with markdown links around it")
  func stripJsonBlock_stripsJsonKeepsMarkdownLinkAround() {
    let input = "see [docs](https://example.com) and the data is {\"k\":1} thanks"
    let out = JsonBlockParser.stripJsonBlock(input)
    #expect(out.contains("[docs](https://example.com)"))
    #expect(!out.contains("\"k\""))
  }

  // MARK: - parseJsonBlocks: unchanged behavior

  @Test("parseJsonBlocks finds a fenced JSON object")
  func parseJsonBlocks_findsFencedJsonObject() {
    let input = "```json\n{\"a\":1}\n```"
    let parsed = JsonBlockParser.parseJsonBlocks(input)
    #expect(parsed.count == 1)
    let dict = parsed.first as? [String: Any]
    #expect(dict?["a"] as? Int == 1)
  }

  @Test("parseJsonBlocks returns empty for plain text with markdown links")
  func parseJsonBlocks_emptyForPlainTextWithMarkdownLinks() {
    let input = "詳しくは [ニッポン放送 YouTube](https://www.youtube.com/watch?v=x)"
    let parsed = JsonBlockParser.parseJsonBlocks(input)
    #expect(parsed.isEmpty)
  }
}
