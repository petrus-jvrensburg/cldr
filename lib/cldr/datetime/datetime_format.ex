defmodule Cldr.DateTime.Format do
  alias Cldr.DateTime.Formatter
  @standard_formats [:short, :medium, :long, :full]

  def format_list do
    known_formats(&all_date_formats/1) ++ known_formats(&all_time_formats/1) ++ known_formats(&all_datetime_formats/1)
  end

  def known_formats(list) do
    Cldr.known_locales()
    |> Enum.map(&(list.(&1)))
    |> List.flatten
    |> Enum.uniq
  end

  def all_date_formats(locale) do
    all_formats_for(locale, &date_formats/2)
  end

  def all_time_formats(locale) do
    all_formats_for(locale, &time_formats/2)
  end

  def all_datetime_formats(locale) do
    all_formats_for(locale, &datetime_formats/2) ++
    all_formats_for(locale, &datetime_available_formats/2)
  end

  defp all_formats_for(locale, type_function) do
    Enum.map(calendars_for_locale(locale), fn calendar ->
      locale
      |> type_function.(calendar)
      |> Map.values
    end)
    |> List.flatten
    |> Enum.uniq
  end

  def calendars_for_locale(locale \\ Cldr.get_current_locale())
  def date_formats(locale \\ Cldr.get_current_locale(), calendar \\ Formatter.default_calendar)
  def time_formats(locale \\ Cldr.get_current_locale(), calendar \\ Formatter.default_calendar)
  def datetime_formats(locale \\ Cldr.get_current_locale(), calendar \\ Formatter.default_calendar)
  def datetime_available_formats(locale \\ Cldr.get_current_locale(), calendar \\ Formatter.default_calendar)

  for locale <- Cldr.Config.known_locales() do
    locale_data = Cldr.Config.get_locale(locale)
    calendars = Cldr.Config.calendars_for_locale(locale_data)

    def calendars_for_locale(unquote(locale)), do: unquote(calendars)

    for calendar <- Cldr.Config.calendars_for_locale(locale_data) do
      calendar_data =
        locale_data
        |> Map.get(:dates)
        |> get_in([:calendars, calendar])

      def date_formats(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(Map.get(calendar_data, :date_formats)))
      end

      def time_formats(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(Map.get(calendar_data, :time_formats)))
      end

      def datetime_formats(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(
          Map.get(calendar_data, :date_time_formats)
          |> Enum.filter(fn {k, _v} -> k in @standard_formats end)
          |> Enum.into(%{})
        ))
      end

      def datetime_available_formats(unquote(locale), unquote(calendar)) do
        unquote(Macro.escape(get_in(calendar_data, [:date_time_formats, :available_formats])))
      end
    end
  end

  def common_datetime_format_names do
    Cldr.known_locales
    |> Enum.map(&datetime_available_formats/1)
    |> Enum.map(&Map.keys/1)
    |> Enum.map(&MapSet.new/1)
    |> intersect_mapsets
    |> MapSet.to_list
  end

  defp intersect_mapsets([a, b | []]) do
    MapSet.intersection(a,b)
  end

  defp intersect_mapsets([a, b | tail]) do
    intersect_mapsets([MapSet.intersection(a,b) | tail])
  end

end