library(shiny)
library(bslib)

# The app keeps helper functions private to the package, then exposes only the
# names needed by ui.R and server.R inside this Shiny app environment.
vorogazeaoi3_helpers <- c(
  "app_head",
  "app_theme",
  "debug_params_list",
  "default_face_dir_path",
  "developer_panel",
  "filter_sanity_fixrep",
  "find_face_file",
  "fixations_panel",
  "format_table_int",
  "hover_coordinate_label",
  "image_position_values",
  "images_panel",
  "list_face_image_files",
  "make_face_file_ui",
  "make_fixrep_mapping_ui",
  "make_sanity_filter_ui",
  "markdown_preview_html",
  "missing_image_position_info",
  "plot_face_image",
  "plot_message",
  "plot_sanity",
  "plot_screen",
  "read_fixrep",
  "req_fixrep_map",
  "sanity_panel",
  "screen_panel",
  "screen_params_from_input",
  "selected_face_dir_path",
  "show_invalid_image_position_modal",
  "standardise_fixrep"
)

for (helper in vorogazeaoi3_helpers) {
  assign(
    x = helper,
    value = get(helper, envir = asNamespace("vorogazeaoi3")),
    envir = environment()
  )
}

rm(helper, vorogazeaoi3_helpers)
