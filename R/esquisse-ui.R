
#' @title Esquisse module
#'
#' @description Use esquisse as a module in a Shiny application.
#'
#' @param id Module ID.
#' @param header Either `TRUE` or `FALSE` to display or not `esquisse` header, or a named `list`
#'  where names are : `settings`, `close`, `import` and `show_data` and values are `TRUE` or
#'  `FALSE` to display or not the corresponding button.
#' @param container Container in which display the addin,
#'  default is to use [esquisse_container()], see examples.
#'  Use `NULL` for no container (behavior in versions <= 0.2.1).
#'  Must be a `function`.
#' @param controls Controls menu to be displayed. Use `NULL` to hide all menus.
#' @param insert_code Logical, Display or not a button to insert the ggplot
#'  code in the current user script (work only in RStudio).
#' @param play_pause Display or not the play / pause button.
#' @param layout_sidebar Put controls in a sidebar on the left rather than below the chart in dropdowns.
#' @param downloads Export options available or `NULL` for no export. See [downloads_labels()].
#' @param n_geoms Number of geoms the user can use.
#'
#' @return A `reactiveValues` with 4 slots :
#'   * **ggobj**: the ggplot object
#'   * **code_plot**: code to generate plot.
#'   * **code_filters**: a list of length two with code to reproduce filters.
#'   * **data**: `data.frame` used in plot (with filters applied).
#'
#'
#' @export
#'
#' @name esquisse-module
#' @order 1
#'
#' @importFrom htmltools tags tagList
#' @importFrom shiny fillPage plotOutput actionButton NS fluidRow column fillCol
#' @importFrom shinyWidgets prettyToggle
#' @importFrom rlang is_list
#' @importFrom utils modifyList
#' @importFrom bslib layout_sidebar sidebar
#'
#' @example examples/esquisse-module-1.R
#'
#' @example examples/esquisse-module-2.R
#'
#' @example examples/esquisse-module-3.R
esquisse_ui <- function(id,
                        header = esquisse_header(),
                        container = esquisse_container(),
                        controls = c("options", "labs", "axes", "geoms", "theme", "filters", "code"),
                        insert_code = FALSE,
                        play_pause = TRUE,
                        layout_sidebar = FALSE,
                        downloads = downloads_labels(),
                        n_geoms = 8) {
  ns <- NS(id)
  header_btns <- esquisse_header()
  if (is_list(header)) {
    header_btns <- modifyList(header_btns, header)
    header <- TRUE
  }
  if (isFALSE(header)) {
    header_btns <- list()
  }
  header_btns <- make_btn_header(header_btns)
  tag_header <- tags$div(
    class = "esquisse-title-container bg-primary d-flex justify-content-between",
    tags$div(
      class = "esquisse-header-btns-left",
      header_btns$.before,
      header_btns$import_data(ns("launch_import_data")),
      header_btns$show_data(ns("show_data")),
      header_btns$update_variable(ns("update_variable")),
      header_btns$create_column(ns("create_col")),
      header_btns$cut_variable(ns("cut_var")),
      header_btns$update_factor(ns("up_fct"))
    ),
    tags$h1("Esquisse", class = "esquisse-title"),
    tags$div(
      class = "esquisse-header-btns-right",
      header_btns$settings(ns("settings")),
      header_btns$.after,
      header_btns$close(ns("close")),
    ),
  )

  ui <- tags$div(
    class = "esquisse-container",
    html_dependency_esquisse(),
    html_dependency_clipboard(),

    if (isTRUE(header)) tag_header,

    if (!isTRUE(layout_sidebar)) {
      tagList(
        select_geom_aes_ui(
          id = ns("geomaes"),
          n_geoms = n_geoms,
          list_geoms = c(
            list(geomIcons()),
            rep_len(list(
              geomIcons(
                c("line", "step", "jitter", "point", "smooth", "density", "boxplot", "violin", "text", "label"),
                default = "select"
              )
            ), n_geoms)
          )
        ),
        fillCol(
          style = "overflow-y: auto;",
          tags$div(
            class = "ggplot-output-container",
            play_pause_input(ns("play_plot"), show = play_pause),
            ggplot_output(
              id = ns("plooooooot"),
              width = "100%",
              height = "100%",
              downloads = if ("export" %in% controls) NULL else downloads
            )
          )
        ),
        controls_ui(
          id = ns("controls"),
          insert_code = insert_code,
          controls = controls,
          downloads = downloads,
          n_geoms = n_geoms
        )
      )
    } else {
      bslib::layout_sidebar(
        padding = 0,
        fillable = FALSE,
        fill = FALSE,
        height = "100%",
        sidebar = bslib::sidebar(
          position = "right",
          # open = "always",
          title = "CONTROLS",
          width = 400,
          controls_ui(
            id = ns("controls"),
            insert_code = insert_code,
            controls = controls,
            layout = "accordion",
            downloads = downloads,
            n_geoms = n_geoms
          )
        ),

        tags$div(
          class = "ggplot-geom-aes-container",
          select_geom_aes_ui(
            id = ns("geomaes"),
            n_geoms = n_geoms,
            list_geoms = c(
              list(geomIcons()),
              rep_len(list(
                geomIcons(
                  c("line", "step", "jitter", "point", "smooth", "density", "boxplot", "violin", "text", "label"),
                  default = "select"
                )
              ), n_geoms)
            )
          ),
          tags$div(
            class = "ggplot-output-sidebar-container",
            play_pause_input(ns("play_plot"), show = play_pause),
            ggplot_output(
              id = ns("plooooooot"),
              width = "100%",
              height = "100%",
              downloads = if ("export" %in% controls) NULL else downloads
            )
          )
        )
      )
    }
  )

  if (is.function(container)) {
    ui <- container(ui)
  }
  return(ui)
}

#' @param width,height The width and height of the container, e.g. `"400px"`,
#'  or `"100%"`; see [htmltools::validateCssUnit()].
#' @param fixed Use a fixed container, e.g. to use use esquisse full page.
#'  If `TRUE`, width and height are ignored. Default to `FALSE`.
#'  It's possible to use a vector of CSS unit of length 4 to specify the margins
#'  (top, right, bottom, left).
#'
#' @rdname esquisse-module
#' @order 3
#'
#' @export
esquisse_container <- function(width = "100%", height = "700px", fixed = FALSE) {
  force(width)
  force(height)
  force(fixed)
  function(...) {
    if (identical(fixed, FALSE)) {
      tag <- tags$div(
        style = sprintf("width: %s;", validateCssUnit(width)),
        style = sprintf("height: %s;", validateCssUnit(height)),
        ...
      )
    } else {
      if (identical(fixed, TRUE)) {
        tag <- tags$div(
          style = "position: fixed; top: 0; bottom: 0; right: 0; left: 0;",
          ...
        )
      } else if (length(fixed) == 4) {
        tag <- tags$div(
          style = do.call(
            sprintf,
            c(list(
              fmt = "position: fixed; top: %s; right: %s; bottom: %s; left: %s;"
            ), lapply(fixed, validateCssUnit))
          ),
          ...
        )
      } else {
        stop(
          "fixed must be ever a logical TRUE/FALSE or a vector of length 4 of valid CSS unit.",
          call. = FALSE
        )
      }
    }
    tagList(
      singleton(tags$head(
        tags$style("html, body {overflow: visible !important;")
      )), tag
    )
  }
}

#' @param import_data Show button to import data.
#' @param show_data Show button to display data.
#' @param update_variable Show button to update selected variables and convert them.
#' @param create_column Show button to create a new column based on an expression.
#' @param cut_variable Show button to allow to convert a numeric variable into factor.
#' @param update_factor Show button to open window to reorder factor levels and update them.
#' @param settings Show button to open settings modal (to select aesthetics to use).
#' @param close Show button to stop the app and close addin.
#' @param .before,.after Custom content to put in the header, typically buttons.
#'
#' @rdname esquisse-module
#' @order 4
#'
#' @export
esquisse_header <- function(import_data = TRUE,
                            show_data = TRUE,
                            update_variable = TRUE,
                            create_column = TRUE,
                            cut_variable = TRUE,
                            update_factor = TRUE,
                            settings = TRUE,
                            close = TRUE,
                            .before = NULL,
                            .after = NULL) {
  list(
    import_data = isTRUE(import_data),
    show_data = isTRUE(show_data),
    update_variable = isTRUE(update_variable),
    create_column = isTRUE(create_column),
    cut_variable = isTRUE(cut_variable),
    update_factor = isTRUE(update_factor),
    settings = isTRUE(settings),
    close = isTRUE(close),
    .before = .before,
    .after = .after
  )
}


make_btn_header <- function(.list) {
  list(
    import_data = if (isTRUE(.list$import_data)) {
      btn_header(i18n("Import data"), "database")
    } else {
      function(id) NULL
    },
    show_data = if (isTRUE(.list$show_data)) {
      show_data_ui
    } else {
      function(id) NULL
    },
    update_variable = if (isTRUE(.list$update_variable)) {
      update_vars_ui
    } else {
      function(id) NULL
    },
    create_column = if (isTRUE(.list$create_column)) {
      create_col_ui
    } else {
      function(id) NULL
    },
    cut_variable = if (isTRUE(.list$cut_variable)) {
      cut_var_ui
    } else {
      function(id) NULL
    },
    update_factor = if (isTRUE(.list$update_factor)) {
      update_fct_ui
    } else {
      function(id) NULL
    },
    settings = if (isTRUE(.list$settings)) {
      btn_header(i18n("Display settings"), "gear-fine")
    } else {
      function(id) NULL
    },
    close = if (isTRUE(.list$close)) {
      btn_header(i18n("Close Window"), "x")
    } else {
      function(id) NULL
    },
    .before = .list$.before,
    .after = .list$.after
  )
}

btn_header <- function(label, icon, class = NULL) {
  function(id) {
    actionButton(
      inputId = id,
      label = if (is.character(icon)) ph(icon, height = "2em", title = label) else icon,
      class = "btn-sm btn-primary",
      title = label,
      class = class
    )
  }
}
