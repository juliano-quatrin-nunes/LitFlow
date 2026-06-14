require "test_helper"

class SetlistExportTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    @setlist = setlists(:one)
    post session_path, params: { email_address: @user.email_address, password: "password" }
  end

  test "can request PDF export for setlist" do
    assert_enqueued_with(job: GenerateSetlistCifraJob, args: [@setlist.id, { format: :pdf }]) do
      get setlist_cifra_pdf_path(@setlist), as: :turbo_stream
    end

    assert_response :success
    assert_match /Gerando PDF.../, response.body
  end

  test "can request DOCX export for setlist" do
    assert_enqueued_with(job: GenerateSetlistCifraJob, args: [@setlist.id, { format: :docx }]) do
      get setlist_cifra_docx_path(@setlist), as: :turbo_stream
    end

    assert_response :success
    assert_match /Gerando DOCX.../, response.body
  end
end
