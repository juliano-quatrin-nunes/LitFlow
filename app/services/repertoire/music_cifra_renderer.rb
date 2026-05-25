require "open3"

class Repertoire::MusicCifraRenderer
  def self.render_pdf(payload)
    new.render(payload, "bin/render_pdf.py")
  end

  def self.render_docx(payload)
    new.render(payload, "bin/render_docx.py")
  end

  def render(payload, script_path)
    # Ensure script is executable
    full_script_path = Rails.root.join(script_path)
    
    # In production/CI we might use a specific python path
    python_path = ENV["PYTHON_PATH"] || "python3"

    stdout, stderr, status = Open3.capture3(python_path, full_script_path.to_s, stdin_data: payload.to_json)

    unless status.success?
      Rails.logger.error("Cifra Renderer failed: #{stderr}")
      raise "Renderer failed: #{stderr}"
    end

    stdout
  end
end
