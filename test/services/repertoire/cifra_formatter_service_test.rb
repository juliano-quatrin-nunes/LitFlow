require "test_helper"

class Repertoire::CifraFormatterServiceTest < ActiveSupport::TestCase
  test "call aligns chords and lyrics in a section" do
    content_json = [
      {
        "type" => "verse",
        "lines" => [
          {
            "parts" => [
              { "chord" => "G", "lyric" => "Text" },
              { "chord" => "C", "lyric" => "" }
            ]
          }
        ]
      }
    ]

    result = Repertoire::CifraFormatterService.call(content_json)

    expected = {
      sections: [
        {
          type: "verse",
          lines: [
            {
              chord_line: "G   C",
              lyric_line: "Text"
            }
          ]
        }
      ]
    }

    assert_equal expected, result
  end

  test "call aligns long chords over short lyrics" do
    content_json = [
      {
        "type" => "verse",
        "lines" => [
          {
            "parts" => [
              { "chord" => "F#m11", "lyric" => "Hi" },
              { "chord" => "B7", "lyric" => "!" }
            ]
          }
        ]
      }
    ]

    result = Repertoire::CifraFormatterService.call(content_json)

    expected = {
      sections: [
        {
          type: "verse",
          lines: [
            {
              chord_line: "F#m11 B7",
              lyric_line: "Hi    !"
            }
          ]
        }
      ]
    }

    assert_equal expected, result
  end

  test "call handles label sections" do
    content_json = [
      {
        "type" => "label",
        "lines" => [
          {
            "parts" => [
              { "lyric" => "Refrão" }
            ]
          }
        ]
      }
    ]

    result = Repertoire::CifraFormatterService.call(content_json)

    expected = {
      sections: [
        {
          type: "label",
          label: "[Refrão]"
        }
      ]
    }

    assert_equal expected, result
  end

  test "as_html returns formatted html string" do
    content_json = [
      {
        "type" => "label",
        "lines" => [ { "parts" => [ { "lyric" => "Refrão" } ] } ]
      },
      {
        "type" => "verse",
        "lines" => [
          {
            "parts" => [
              { "chord" => "G", "lyric" => "Text" },
              { "chord" => "C", "lyric" => "" }
            ]
          }
        ]
      }
    ]

    result = Repertoire::CifraFormatterService.as_html(content_json)

    expected = <<~HTML.strip
      <pre style="font-family: 'Roboto Mono', monospace;">[Refrão]

      <b>G</b>   <b>C</b>
      Text</pre>
    HTML

    assert_equal expected, result
  end

  test "call handles multiple lines in a section" do
    content_json = [
      {
        "type" => "verse",
        "lines" => [
          {
            "parts" => [ { "chord" => "G", "lyric" => "Line 1" } ]
          },
          {
            "parts" => [ { "chord" => "C", "lyric" => "Line 2" } ]
          }
        ]
      }
    ]

    result = Repertoire::CifraFormatterService.call(content_json)

    expected = {
      sections: [
        {
          type: "verse",
          lines: [
            {
              chord_line: "G",
              lyric_line: "Line 1"
            },
            {
              chord_line: "C",
              lyric_line: "Line 2"
            }
          ]
        }
      ]
    }

    assert_equal expected, result
  end
end
