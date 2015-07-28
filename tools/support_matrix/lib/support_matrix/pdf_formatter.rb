require "prawn"
require "prawn/table"
class PdfFormatter
  attr_reader :document

  def initialize
    @document = Prawn::Document.new(page_layout: :landscape)
  end

  def write(matrix, path)
    full_path = File.join(path, "Machinery_support_matrix.pdf")

    legend
    integration_tests_sheet(matrix)
    unit_tests_sheet(matrix)
    runs_on_sheet(matrix)
    sections

    @document.render_file(full_path)
    full_path
  end

  private

  def sections
    @document.outline.define do
      section("Legend", destination: 1)
      section("Integration Tests") do
        page title: "Inspect", destination: 2
        page title: "Build", destination: 3
        page title: "Export", destination: 4
        page title: "Analyze", destination: 5
        page title: "Deploy", destination: 6
      end
      section("Unit Tests", destination: 7)
      section("Runs On", destination: 8)
    end
  end

  def legend
    @document.text "Legend", align: :center, size: 24
    @document.move_down 12

    rows = []

    rows << [cell("Support Status (colors)", :header), cell("Tests Groups (letters)", :header)]
    rows << [cell("supported", :supported), "M = Minimal (run locally before checking in)"]
    rows << [
      cell("working", :working),
      "A = Acceptance (run for pull requests before going to master)"
    ]
    rows << [
      cell("future support", :future_support),
      "F = Full (all integration tests run through jenkins against master after checkin)"
    ]
    rows << [cell("unsupported", :unsupported), ""]

    @document.table(rows, cell_style: { size: 8 })

    @document.start_new_page
  end

  def integration_tests_sheet(matrix)
    @document.text "Integration Tests", align: :center, size: 24
    @document.move_down 22

    matrix.integration_tests.each do |test, support|
      rows = []

      rows << [
        @document.make_cell(test,
                            colspan: matrix.integration_tests_cols.values.flatten.size + 2,
                            background_color: "e6e6e6")
      ]

      rows << ["", cell("Target", :vertical)] +
        matrix.integration_tests_cols.map do |os, architectures|
          @document.make_cell(os, colspan: architectures.size, rotate: 90, valign: :bottom)
        end

      archs = []
      matrix.integration_tests_cols.each do |_os, architectures|
        architectures.each { |arch| archs << cell(arch, :small_vertical) }
      end
      rows << ["host", ""] + archs

      matrix.integration_tests_rows.each do |host_system, host_architectures|
        host_architectures.each do |host_arch|
          data = []
          matrix.integration_tests_cols.each do |target_system, target_architectures|
            target_architectures.each do |target_arch|
              host = [host_system, host_arch].compact.join(":")
              target = [target_system, target_arch].compact.join(":")
              created = false
              support.each do |status, support_data|
                if support_data.include?(host)
                  exists = support_data[host].include?(target)
                  group = support_data[host][target]
                  if group
                    data << cell(matrix.test_group_char[group], status.to_sym)
                    created = true
                  elsif exists
                    data << cell("", status.to_sym)
                    created = true
                  end
                end
              end
              data << "" unless created
            end
          end
          rows << [host_system, host_arch] + data
        end
      end

      @document.table(rows, cell_style: { size: 8, padding: [1, 1, 1, 1] })
      @document.start_new_page
    end
  end

  def unit_tests_sheet(matrix)
    @document.text "Unit Tests", align: :center, size: 24
    @document.move_down 12

    rows = []

    matrix.unit_tests.each do |status, hosts|
      rows << [
        { content: status,
          colspan: 3,
          background_color: "e6e6e6" }
      ]

      rows << ["host", "arch", "ruby version"]

      hosts.each do |host, ruby_version|
        host_system, host_arch = host.split(":")
        rows << [host_system, host_arch, ruby_version]
      end
    end

    @document.table(rows, cell_style: { size: 8 })

    @document.start_new_page
  end

  def runs_on_sheet(matrix)
    @document.text "Runs On", align: :center, size: 24
    @document.move_down 12

    rows = []

    vertical = ["", "Action"] + matrix.runs_on_cols.keys
    rows << vertical.map { |content| cell(content, :vertical) }
    rows << ["Host", ""] + [""] * matrix.runs_on_cols.size

    matrix.runs_on_rows.each do |os, architectures|
      architectures.each do |arch|
        elements = []
        matrix.runs_on_cols.keys.each do |action|
          tech = [os, arch].compact.join(":")
          %w(supported unsupported working).each do |support|
            group = matrix.runs_on.fetch(support, {}).fetch(tech, {}).fetch(action, false)
            elements << cell(matrix.test_group_char[group], support.to_sym) unless group === false
          end
        end
        rows << [os, arch] + elements
      end
    end

    @document.table(rows, cell_style: { size: 8 })
  end

  def styles
    {
      supported: {
        background_color: "00ff00", font_style: :bold
      },
      unsupported: {
        background_color: "ff9696", font_style: :bold
      },
      working: {
        background_color: "83caff", font_style: :bold
      },
      future_support: {
        background_color: "ffffcc", font_style: :bold
      },
      header: {
        background_color: "e6e6e6", font_style: :bold
      },
      vertical: {
        rotate: 90,
        height: 90,
        valign: :bottom
      },
      small_vertical: {
        rotate: 90,
        height: 50,
        valign: :bottom
      }
    }
  end

  def cell(content, style)
    @document.make_cell(content, styles[style])
  end
end
