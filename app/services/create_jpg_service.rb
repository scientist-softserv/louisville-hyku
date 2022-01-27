# frozen_string_literal: true

class CreateJpgService
  attr_accessor :files, :results, :cached

  def initialize(files, user, cached: false)
    @files = files
    @user = user
    @results = []
    @cached = cached
  end

  def valid_file?(file)
    file.present? && File.extname(file) == ".pdf" && !File.basename(file).match(/full-work.pdf$/)
  end

  def file_name_and_path_for(file)
    [File.basename(file["file"], ".pdf"), file.file.path]
  end

  def file_name_and_path_for_remote(file)
    [File.basename(file, ".pdf"), file.path]
  end

  def directory_for(file_name)
    directory = Rails.root.join("tmp", "uploads", "jpgs", file_name)
    FileUtils.mkdir_p directory unless File.exist?(directory)
    directory
  end

  def page_count_for(pdf_path)
    cmd = "exiftool -PageCount -s3 #{pdf_path}"
    page_count, page_status = run(cmd)
    raise "Failed to parse PDF, could not get page count #{cmd}: #{page_count}" unless page_status.success?
    page_count.first.to_i
  end

  def check_for_errors(cmd_results)
    errors = cmd_results.reject do |set|
      set[2].success?
    end
    raise "Failed to parse PDF: #{errors}" if errors.present?
  end

  def create_uploaded_files(_file, directory, user_id)
    Dir.glob("#{directory}/*.jpg").sort.map do |jpg|
      File.open(Rails.root.join(jpg)) do |jpg_file|
        Hyrax::UploadedFile.create(file: jpg_file, user_id: user_id, derived: true)
      end
    end
  end

  def files_present?(directory)
    return true if cached
    Dir.glob("#{directory}/*.jpg").size.positive?
  end

  def create_jpgs
    files.each do |file|
      next unless valid_file?(file['file'])
      file_name, pdf_path = file_name_and_path_for(file)
      directory = directory_for(file_name)
      unless files_present?(directory)
        page_count = page_count_for(pdf_path)

        cmd_results = []
        page_count.times do |i|
          cmd = "vips copy #{pdf_path}[dpi=400,page=#{i},n=1] #{directory.join(file_name)}-#{i.to_s.rjust(6, '0')}.jpg"
          output, status = run(cmd)
          cmd_results << [cmd, output, status]
        end

        check_for_errors(cmd_results)
      end
      self.results += create_uploaded_files(file, directory, file.user)
    end
    self.results
  end

  def run(cmd)
    Rails.logger.info("CMD: #{cmd}")
    output = []
    IO.popen(cmd) do |io|
      output << io.gets
    end
    [output, $CHILD_STATUS]
  end

  def create_jpgs_from_remote_pdf
    name = URI(files).path.split('/').last
    return if name.nil?
    return unless name.split('.').last == 'pdf'
    File.open(name, 'wb') do |file|
      next unless valid_file?(files)
      file << open(files).read
      next unless valid_file?(file)
      file_name, pdf_path = file_name_and_path_for_remote(file)
      directory = directory_for(file_name)
      unless files_present?(directory)
        page_count = page_count_for(file.path)
        cmd_results = []
        page_count.times do |i|
          cmd = "vips copy #{pdf_path}[dpi=400,page=#{i},n=1] #{directory.join(file_name)}-#{i.to_s.rjust(6, '0')}.jpg"
          output, status = run(cmd)
          cmd_results << [cmd, output, status]
        end
        check_for_errors(cmd_results)
      end
      self.results += create_uploaded_files(file, directory, @user.id)
    end
    File.delete(name) if File.exist? name
    self.results
  end
  # rubocop:enable Metrics/AbcSize
end
