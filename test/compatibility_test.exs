# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
defmodule CompatibilityTest do
  use ExUnit.Case

  test "google_spreadsheet.xlsx" do
    assert {:ok, package} =
             XlsxReader.open(
               TestFixtures.path("google_spreadsheet.xlsx"),
               supported_custom_formats: [{"mmmm d", :date}]
             )

    assert ["Sheet1"] = XlsxReader.sheet_names(package)

    assert {:ok,
            [
              ["integer", 123.0],
              ["float", 123.456],
              ["percentage", 12.5],
              ["date", ~D[2019-11-15]],
              ["time", ~N[1899-12-30 11:45:00]],
              ["ticked\n", true],
              ["unticked", false],
              ["image", ""]
            ]} = XlsxReader.sheet(package, "Sheet1")
  end

  test "merged.xlsx" do
    assert {:ok, package} = XlsxReader.open(TestFixtures.path("merged.xlsx"))

    assert ["merged"] = XlsxReader.sheet_names(package)

    assert {:ok,
            [
              ["horizontal", "", "vertical"],
              ["horizontal + vertical", "", ""],
              ["", "", "none"]
            ]} = XlsxReader.sheet(package, "merged")
  end

  test "file generated by elixlsx" do
    test_row = [
      "string1",
      "",
      nil,
      :empty,
      "string1",
      "string2",
      123,
      true,
      false
    ]

    workbook = %Elixlsx.Workbook{
      sheets: [
        %Elixlsx.Sheet{
          name: "sheet1",
          rows: [
            test_row
          ]
        },
        %Elixlsx.Sheet{name: "sheet2", rows: []}
      ]
    }

    assert {:ok, {_filename, zip_binary}} = Elixlsx.write_to_memory(workbook, "test.xlsx")

    assert {:ok, package} = XlsxReader.open(zip_binary, source: :binary)

    assert ["sheet1", "sheet2"] = XlsxReader.sheet_names(package)

    assert {:ok,
            [
              [
                "string1",
                "",
                nil,
                nil,
                "string1",
                "string2",
                123.0,
                true,
                false
              ]
            ]} = XlsxReader.sheet(package, "sheet1", blank_value: nil)

    assert {:ok, []} = XlsxReader.sheet(package, "sheet2")
  end

  test "file with omitted row elements" do
    assert {:ok, package} = XlsxReader.open(TestFixtures.path("omitted_row.xlsx"))

    assert {:ok, [["", ""], ["", "b2"]]} = XlsxReader.sheet(package, "Sheet1", empty_rows: true)
    assert {:ok, [["", "b2"]]} = XlsxReader.sheet(package, "Sheet1", empty_rows: false)
  end
end
