require 'fileutils'

TODO = <<-TXT
  - Save As...
  - Syntax Highlighting
TXT

class LilyponderController
  attr_accessor :pdf_view, :text_view, :regenerate_button
  attr_accessor :error_label, :progress_bar
  
  LILYPOND_EXECUTABLE = "/Applications/Lilypond.app/Contents/Resources/bin/lilypond"
  SUPPORT_DIR = "~/Application Support/Lilyponder".stringByExpandingTildeInPath
  GENERIC_FILENAME = "#{SUPPORT_DIR}/file"
  LY_FILENAME = GENERIC_FILENAME + ".ly"
  PDF_FILENAME = GENERIC_FILENAME + ".pdf"

  def awakeFromNib
    set_up_filesystem
    read_from_ly_file if ly_file_exists?
    reload_pdf        if pdf_file_exists?
    @text_view.setDelegate(self)
  end

  # Called when @text_view loses focus
  def textDidEndEditing(notification)
    regenerate_pdf(notification)
  end

  # Called when the "Regenerate PDF" button is pushed
  # or from textDidEndEditing above
  def regenerate_pdf(sender)
    write_to_ly_file
    run_lilypond_task(sender)
    reload_pdf
  end

  def reload_pdf
    data = NSData.dataWithContentsOfFile(PDF_FILENAME)
    document = PDFDocument.new.initWithData(data)
    @pdf_view.setDocument(document)
  end

  def run_lilypond_task(sender)
    task = NSTask.launchedTaskWithLaunchPath(LILYPOND_EXECUTABLE,
      arguments:["-o#{GENERIC_FILENAME}", LY_FILENAME])
    set_visibilities_during_lilypond_task(sender)
    task.waitUntilExit
    handle_results(task)
  end

  def set_visibilities_during_lilypond_task(sender)
    @pdf_view.setHidden(true)
    @error_label.setHidden(true)
    @progress_bar.setHidden(false)
    @progress_bar.startAnimation(sender)
  end

  def handle_results(task)
    @progress_bar.setHidden(true)
    case task.terminationStatus
    when 0
      @pdf_view.setHidden(false)
    when 1
      @error_label.setHidden(false)
    end
  end

  def read_from_ly_file
    file = File.open(LY_FILENAME, "r")
    @text_view.insertText(file.readlines.join(""))
    file.close
  end

  def write_to_ly_file
    clean_text_view_string
    File.open(LY_FILENAME, "w") do |file|
      file << @text_view.string
    end
  end

  def clean_text_view_string
    @text_view.insertText(" ") if @text_view.string == ""
  end

  def set_up_filesystem
    FileUtils.mkdir_p(SUPPORT_DIR) unless File.exists?(SUPPORT_DIR)
    FileUtils.touch(LY_FILENAME)
  end

  def ly_file_exists?;  File.exists?(LY_FILENAME);  end
  def pdf_file_exists?; File.exists?(PDF_FILENAME); end
end
