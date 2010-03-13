require 'test/test_helper'

class IntegrationController < ActionController::Base

  PERFORM_XHR_FUNCTION = <<-JS
    function perform_xhr(method, url) {
      var xhr = new XMLHttpRequest()
      xhr.open(method, url, false) //false == synchronous
      xhr.onreadystatechange = function() {
        if (this.readyState != 4) { return }
        document.body.innerHTML = this.responseText
      }
      xhr.send(null) // POST request sends data here
    }
  JS

  def baz
    render :text => <<-HTML
      <html>
        <head>
          <script>#{PERFORM_XHR_FUNCTION}</script>
        </head>
        <body></body>
      </html>
    HTML
  end

  def boo
    render :text => <<-HTML
      <html>
        <head>
          <script>#{PERFORM_XHR_FUNCTION}</script>
          <script>
            window.onload = function() {
              perform_xhr("GET", "xhr")
            }
          </script>
        </head>
        <body></body>
      </html>
    HTML
  end

  def xhr
    render :text => "xhr response"
  end
end

class IntegrationControllerTest < ActionController::IntegrationTest

  # TODO test xhr POST
  # TODO test xhr uris with initial "/"

  test "api" do
    assert_respond_to self, :execute_javascript
    assert_respond_to self, :js
  end

  ## xhr

  test "xhr calls controller" do
    get 'baz'

    assert_equal "", js(<<-JS).gsub("\n",'').strip
      document.body.innerHTML
    JS
    assert_equal "xhr response", js(<<-JS)
      perform_xhr("GET", "xhr")
      document.body.innerHTML
    JS
  end

  test "xhr identifes properly" do
    get 'baz'
    assert_nil request.headers['X-Requested-With']

    js(<<-JS)
      perform_xhr("GET", "xhr")
    JS
    assert_equal 'XMLHttpRequest', request.headers['X-Requested-With']
  end

  test "xhr is mocked early" do
    get 'boo'
    assert_equal "xhr response", js(<<-JS)
      document.body.innerHTML
    JS
  end
end
