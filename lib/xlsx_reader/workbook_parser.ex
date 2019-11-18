defmodule XlsxReader.WorkbookParser do
  @moduledoc """

  Parses a workbook XML filee to extract the list of sheets and determine the date system in use.

  """

  @behaviour Saxy.Handler

  alias XlsxReader.{ParserUtils, Conversion}

  def parse(xml) do
    Saxy.parse_string(xml, __MODULE__, %XlsxReader.Workbook{})
  end

  @impl Saxy.Handler
  def handle_event(:start_document, _prolog, workbook) do
    {:ok, workbook}
  end

  @impl Saxy.Handler
  def handle_event(:end_document, _data, workbook) do
    {:ok, %{workbook | base_date: workbook.base_date || Conversion.base_date(1900)}}
  end

  @impl Saxy.Handler
  def handle_event(:start_element, {"workbookPr", attributes}, workbook) do
    {:ok, %{workbook | base_date: attributes |> date_system() |> Conversion.base_date()}}
  end

  @impl Saxy.Handler
  def handle_event(:start_element, {"sheet", attributes}, workbook) do
    {:ok, %{workbook | sheets: [build_sheet(attributes) | workbook.sheets]}}
  end

  @impl Saxy.Handler
  def handle_event(:start_element, _element, workbook) do
    {:ok, workbook}
  end

  @impl Saxy.Handler
  def handle_event(:end_element, "sheets", workbook) do
    {:ok, %{workbook | sheets: Enum.reverse(workbook.sheets)}}
  end

  @impl Saxy.Handler
  def handle_event(:end_element, _name, workbook) do
    {:ok, workbook}
  end

  @impl Saxy.Handler
  def handle_event(:characters, _chars, workbook) do
    {:ok, workbook}
  end

  ##

  @sheet_attributes %{
    "name" => :name,
    "r:id" => :rid,
    "sheetId" => :sheet_id
  }

  defp build_sheet(attributes) do
    Enum.reduce(
      attributes,
      %XlsxReader.Sheet{},
      fn {name, value}, sheet ->
        case Map.fetch(@sheet_attributes, name) do
          {:ok, key} ->
            %{sheet | key => value}

          :error ->
            sheet
        end
      end
    )
  end

  defp date_system(attributes) do
    if ParserUtils.get_attribute(attributes, "date1904", "0") == "1",
      do: 1904,
      else: 1900
  end
end
