require "odf/spreadsheet"
class OdsFormatter
  attr_reader :workbook
  def initialize
    @workbook = ODF::Spreadsheet.new
  end

  def write(matrix, path)
    full_path = File.join(path, "Machinery_support_matrix.ods")
    style_definitions
    integration_tests_sheet(matrix)
    unit_tests_sheet(matrix)
    runs_on_sheet(matrix)

    return full_path if workbook.write_to(full_path)
  end

  private

  def style_definitions
    workbook.style "unsupported", family: :cell do
      property :cell,
        "background-color" => "#ff9696",
        "border" => "0.002cm solid #000000"
      property :text, "font-weight" => "bold"
    end

    workbook.style "small-unsupported", family: :cell do
      property :cell,
        "background-color" => "#ff9696",
        "border" => "0.002cm solid #000000"
      property :text, "font-size" => "8"
    end

    workbook.style "future_support", family: :cell do
      property :cell,
        "background-color" => "#ffffcc",
        "border" => "0.002cm solid #000000"
      property :text, "font-weight" => "bold"
    end

    workbook.style "small-future_support", family: :cell do
      property :cell,
        "background-color" => "#ffffcc",
        "border" => "0.002cm solid #000000"
      property :text, "font-size" => "8"
    end

    workbook.style "supported", family: :cell do
      property :cell,
        "background-color" => "#00ff00",
        "border" => "0.002cm solid #000000"
      property :text, "font-weight" => "bold"
    end

    workbook.style "small-supported", family: :cell do
      property :cell,
        "background-color" => "#00ff00",
        "border" => "0.002cm solid #000000"
      property :text, "font-size" => "8"
    end

    workbook.style "working", family: :cell do
      property :cell,
        "background-color" => "#83caff",
        "border" => "0.002cm solid #000000"
      property :text, "font-weight" => "bold"
    end

    workbook.style "small-working", family: :cell do
      property :cell,
        "background-color" => "#83caff",
        "border" => "0.002cm solid #000000"
      property :text, "font-size" => "8"
    end

    workbook.style "empty", family: :cell do
      property :cell, "border" => "0.002cm solid #000000"
    end

    workbook.style "small", family: :cell do
      property :cell, "border" => "0.002cm solid #000000"
      property :text, "font-size" => "8"
    end

    workbook.style "table-header", family: :cell do
      property :cell, "background-color" => "#e6e6e6",
                      "border" => "0.002cm solid #000000"
    end

    workbook.style "centered-small-table-header", family: :cell do
      property :cell, "background-color" => "#e6e6e6",
                      "border" => "0.002cm solid #000000"
      property :paragraph, "text-align" => "center"
      property :text, "font-size" => "8"
    end

    workbook.style "4cm-width", family: :column do
      property :column, "column-width" => "4cm"
    end

    workbook.style "4cm-hight", family: :row do
      property :row, "row-height" => "4cm"
    end

    workbook.style "3cm-hight", family: :row do
      property :row, "row-height" => "3cm"
    end

    workbook.style "1.5cm-hight", family: :row do
      property :row, "row-height" => "1.5cm"
    end

    workbook.style "vertical", family: :cell do
      property :cell, "rotation-angle" => "90",
                      "border" => "0.002cm solid #000000"
    end

    workbook.style "square", family: :column do
      property :column, "column-width" => "0.7cm"
    end
  end

  def integration_tests_sheet(matrix)
    workbook.table "Integration Tests" do
      row
      row do
        cell
        cell "Support Status (colors)", style: "centered-small-table-header"
        cell "Tests Groups (letters)", style: "centered-small-table-header", span: 11
      end
      row do
        cell
        cell style: "small"
        cell style: "small", span: 11
      end
      row do
        cell
        cell "supported", style: "small-supported"
        cell "M = Minimal (run locally before checking in)", style: "small", span: 11
      end
      row do
        cell
        cell "working", style: "small-working"
        cell "A = Acceptance (run for pull requests before going to master)",
             style: "small", span: 11
      end
      row do
        cell
        cell "future support", style: "small-future_support"
        cell "F = Full (all integration tests run through jenkins against master after checkin)",
             style: "small", span: 11
      end
      row do
        cell
        cell "unsupported", style: "small-unsupported"
        cell style: "small", span: 11
      end
      row do
        cell
        cell "no data", style: "small"
        cell style: "small", span: 11
      end

      column style: "square"
      column style: "4cm-width"
      column
      matrix.integration_tests_cols.values.flatten.size.times do
        column style: "square"
      end

      matrix.integration_tests.each do |test, support|
        row
        row do
          cell
          cell test, style: "table-header",
                     span: matrix.integration_tests_cols.values.flatten.size + 2
        end

        row do
          self.style = "3cm-hight"
          cell
          cell style: "empty"
          cell "Target", style: "vertical"
          matrix.integration_tests_cols.each do |os, architectures|
            cell os, span: architectures.size, style: "vertical"
          end
        end

        row do
          self.style = "1.5cm-hight"
          cell
          cell "Host", style: "empty"
          cell style: "empty"
          matrix.integration_tests_cols.each do |_os, architectures|
            architectures.each do |arch|
              cell arch, style: "vertical"
            end
          end
        end

        matrix.integration_tests_rows.each do |host_system, host_architectures|
          host_architectures.each do |host_arch|
            row do
              cell
              cell host_system, style: "empty"
              cell host_arch, style: "empty"

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
                        cell matrix.test_group_char[group], style: status
                        created = true
                      elsif exists
                        cell "", style: status
                        created = true
                      end
                    end
                  end
                  cell "", style: "empty" unless created
                end
              end
            end
          end
        end
      end
    end
  end

  def unit_tests_sheet(matrix)
    workbook.table "Unit Tests" do
      column style: "square"
      column style: "4cm-width"

      matrix.unit_tests.each do |status, hosts|
        row
        row do
          cell
          cell status, span: 3, style: "table-header"
        end

        row do
          cell
          cell "host", style: "table-header"
          cell "arch", style: "table-header"
          cell "ruby version", style: "table-header"
        end

        hosts.each do |host, ruby_version|
          host_system, host_arch = host.split(":")
          row do
            cell
            cell host_system, style: "empty"
            cell host_arch, style: "empty"
            cell ruby_version, style: "empty"
          end
        end
      end
    end
  end

  def runs_on_sheet(matrix)
    workbook.table "Runs On" do
      column style: "square"
      column style: "4cm-width"
      column
      matrix.runs_on_cols.size.times do
        column style: "square"
      end

      row
      row do
        self.style = "4cm-hight"
        cell
        cell style: "empty"
        cell "Action", style: "vertical"
        matrix.runs_on_cols.keys.each do |action|
          cell action, style: "vertical"
        end
      end
      row do
        cell
        cell "Host", style: "empty"
        cell style: "empty"
        matrix.runs_on_rows.size.times do
          cell style: "empty"
        end
      end

      matrix.runs_on_rows.each do |os, architectures|
        architectures.each do |arch|
          row do
            cell
            cell os, style: "empty"
            cell arch, style: "empty"
            matrix.runs_on_cols.keys.each do |action|
              tech = [os, arch].compact.join(":")
              %w(supported unsupported working).each do |support|
                group = matrix.runs_on.fetch(support, {}).fetch(tech, {}).fetch(action, false)
                cell matrix.test_group_char[group], style: support unless group === false
              end
            end
          end
        end
      end
    end
  end
end
