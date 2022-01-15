require 'open3'
require 'tmpdir'

# Adapter class composes a PDF derivative for a work, if it requires one.
class PDFComposer
  attr_accessor :work, :page_pdfs

  CMD_BASE = "gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite".freeze

  # @param work [NewspaperWork] adapts work work object
  def initialize(work)
    @work = work
    # paths to page PDFs
    @page_pdfs = []
  end

  def compose
    # we will not step on any existing PDF
    return if work_pdf_exists?
    # we can not compose a multi-page work PDF if constituent page PDFs
    #   do not exist (yet == not ready, possibly waiting on an async job).
    @page_pdfs = validated_page_pdfs
    # Compose a Ghostscript command to merge all paths in @page_pdfs into
    #   a single output document, execute:
    compose_from_pages
  end

  def compose_from_pages
    outfile = File.join(Dir.mktmpdir, output_filename)
    sources = @page_pdfs.join(' ')
    cmd = "#{CMD_BASE} -sOutputFile=#{outfile} #{sources}"
    # rubocop:disable Lint/UnusedBlockArgument
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      unless wait_thr.value.success?
        e = "Ghostscript Error: \n#{stderr.read}"
        raise NewspaperWorks::DataError, e
      end
    end
    # rubocop:enable Lint/UnusedBlockArgument
    # at this point, something should exist and validate at path `outfile`:
    raise NewspaperWorks::DataError, "Generated PDF invalid" unless validate_pdf(outfile)
    # Assign for attachment to work, commit:
    attach_to_work(outfile)
  end

  def output_filename
    "#{@work.id}_full-work.pdf"
  end

  # Validate PDF with poppler `pdfinfo` command, which will detect
  #   error conditions in cases like truncated PDF, and only in those
  #   error conditions will write to stderr.
  # @param path [String] path to PDF file
  # @return [Boolean] true or false
  def validate_pdf(path)
    return false if path.nil? || !File.exist?(path)
    return false if File.size(path).zero?
    result = ''
    cmd = "pdfinfo #{path}"
    # rubocop:disable Lint/UnusedBlockArgument
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      result = stderr.read
    end
    # rubocop:enable Lint/UnusedBlockArgument
    # only zero bytes stderr output from `pdfinfo` considered valid PDF:
    result.size.zero?
  end

  private

    # @return [Array] list of paths to page PDFs, in page order
    # @raises [NewspaperWorks::PagesNotReady] if any page has invalid
    #   or non-ready PDF source.
    def validated_page_pdfs
      result = []
      # if any page PDF invalid, raise; otherwise append to result:
      pages.each_with_index do |page, idx|
        e = "Page PDFs not ready for work "\
          "(Work id: #{work.id}, Page index: #{idx})"
        path = derivatives_of(page).path('pdf')
        raise NewspaperWorks::PagesNotReady, e unless validate_pdf(path)
        result.push(path)
      end
      result
    end

    def pages
      @pages ||= work.file_sets.select do |fs|
        e = "Page PDFs not ready for work "\
          "(Work id: #{work.id}, Page id: #{fs.id})"
        raise NewspaperWorks::PagesNotReady, e if fs.mime_type.blank?
        fs.mime_type.match('image') && !fs.is_derived
      end
    end

    def work_pdf_exists?
      @work.file_sets.detect do |fs|
        e = "Page PDFs not ready for work "\
          "(Work id: #{work.id}, Page id: #{fs.id})"
        raise NewspaperWorks::PagesNotReady, e if fs.mime_type.blank?
        fs.mime_type == "application/pdf"
      end
    end

    def derivatives_of(work)
      NewspaperWorks::Data::WorkDerivatives.of(work)
    end

    def ensure_whitelist
      whitelist = Hyrax.config.whitelisted_ingest_dirs
      whitelist.push(Dir.tmpdir) unless whitelist.include?(Dir.tmpdir)
    end

    def attach_to_work(path)
      ensure_whitelist
      # We rely upon WorkFiles to create fileset, and by consequence of
      #   running primary file attachment through actor stack,
      #   visibility of the FileSet is copied from the work:
      attachment = NewspaperWorks::Data::WorkFiles.of(@work)
      attachment.assign(path)
      attachment.commit!
    end
end
