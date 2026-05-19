library(shiny)
library(bslib)

ui <- page_fillable(
  title = "Vorogaze",
  
  theme = bs_theme(
    version = 5,
    base_font_size = "0.9rem",
    "input-font-size" = "0.8rem",
    "input-padding-y" = "0.15rem",
    "input-padding-x" = "0.4rem"
  ),
  
  tags$head(
    tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = "styles.css"
    )
  ),
  
  navset_card_pill(
    
    nav_panel(
      "fixations",
      layout_columns(
        col_widths = c(4, 8),
        
        card(
          card_header("input"),
          # fixation report upload goes here
          card_body(
            div(
              class = "fixrep-upload-box",
              
              fileInput(
                "upload_fixrep",
                "Upload fixation report",
                width = "100%"
              )
            ),
            
            div(
              class = "fixrep-mapping-ui",
              uiOutput("fixrep_mapping_ui")
            )
          )
        ),
        
        layout_columns(
          col_widths = 12,
          
          card(
            card_header("raw"),
            card_body(
              div(
                class = "compact-table-output",
                tableOutput("fixrep_raw_preview")
              )
            )
          ),
          
          card(
            card_header("processed"),
            card_body(
              div(
                class = "compact-table-output",
                tableOutput("fixrep_preview")
              )
            )
          )
        )
      )
    ),
    
    nav_panel(
      "screen",
      layout_columns(
        col_widths = c(4, 8),
        
        card(
          card_header("input"),
          card_body(
            radioButtons(
              "screen_origin",
              "Screen origin",
              choices = c(
                "Top left" = "top_left",
                "Centre" = "center",
                "Other" = "other"
              ),
              selected = "top_left"
            ),
            
            numericInput(
              "screen_left",
              "Screen left",
              value = 0,
              step = 1
            ),
            
            numericInput(
              "screen_right",
              "Screen right",
              value = 1600,
              step = 1
            ),
            
            numericInput(
              "screen_top",
              "Screen top",
              value = 900,
              step = 1
            ),
            
            numericInput(
              "screen_bottom",
              "Screen bottom",
              value = 0,
              step = 1
            )
          )
        ),
        
        card(
          card_header("view"),
          card_body(
            plotOutput("view_screen")
          )
        )
      )
    ),
    
    nav_panel(
      "images",
      layout_columns(
        col_widths = c(4, 8),
        
        card(
          card_header("input"),
          card_body(
            checkboxInput(
              "use_bundled_face",
              "Use bundled face",
              value = FALSE
            ),
            
            fileInput(
              "upload_face",
              "Upload face image",
              accept = c(".png", ".jpg", ".jpeg")
            ),
            
            radioButtons(
              "image_origin",
              "Image origin",
              choices = c(
                "Top left" = "top_left",
                "Centre" = "center",
                "Other" = "other"
              ),
              selected = "top_left"
            )
          )
        ),
        
        card(
          card_header("view"),
          # image view outputs go here
          card_body(
            plotOutput("view_face")
          )
        )
      )
    ),
    
    nav_panel(
      "sanity",
      layout_columns(
        col_widths = c(4, 8),
        
        card(
          card_header("verify params"),
          card_body(
            checkboxInput(
              "face_centered_on_screen",
              "Face was presented in center of screen",
              value = TRUE
            )
          )
        ),
        
        card(
          card_header("view everything"),
          card_body(
            plotOutput("view_sanity", width = "100%", height = "600px")
          )
        )
      )
    )
    
    
  )
)