# remotes::install_github("h-a-graham/rayvista", dependencies=TRUE)
# remotes::install_github("tylermorganwall/rayrender")
# remotes::install_github("tylermorganwall/rayshader")

library(rayvista)
library(dplyr)
library(rayshader)

locations <- list(
    kilmelford = list(lat = 56.25595582307193,
                      long =  -5.493112190212445),
    easdale = list(lat = 56.2944296138012,
                   long = -5.649431887657433),
    onich = list(lat = 56.70322139528867,
                 long = -5.236364398304087),
    glenelg = list(lat = 57.224625524472145,
                   long = -5.637623992676892),
    uigg = list(lat = 57.585932759422775,
                long = -6.379115862714244),
    achtriochtan = list(lat = 56.66451664516608,
                        long = -5.039375858643843)
    )
    



future::plan(future::multisession(workers = 3))
sites <- furrr::future_map(locations,
                           ~plot_3d_vista(lat = .x$lat,
                                          long = .x$long,
                                          radius = 10^4,
                                          phi=30, 
                                          outlier_filter =0.001,
                                          show_vista = FALSE ,
                                          zscale = 20))
future::plan(future::sequential())

saveRDS(sites, file = 'out/data/scotland_trip/vistas.Rds')
sites <- readRDS('out/data/scotland_trip/vistas.Rds')

# cleaning ----------------------------------------------------------------




sites$achtriochtan$dem_matrix[is.na(sites$achtriochtan$dem_matrix)] <- min(sites$achtriochtan$dem_matrix, na.rm = TRUE)
sites$kilmelford$dem_matrix[is.na(sites$kilmelford$dem_matrix)] <- min(sites$kilmelford$dem_matrix, na.rm = TRUE)
sites$uigg$dem_matrix[is.na(sites$uigg$dem_matrix)] <- min(sites$uigg$dem_matrix, na.rm = TRUE)


# parameters --------------------------------------------------------------


settings <- list(
    kilmelford = list(phi = 45, theta = 300, zscale = 1.75),
    easdale = list(phi = 45, theta = 270, zscale = 1),
    onich = list(phi = 45, theta = 310, zscale = 1.75),
    glenelg = list(phi = 45, theta = 320, zscale = 2),
    uigg = list(phi = 45, theta = 320, zscale = 2),
    achtriochtan = list(phi = 45, theta = 295, zscale = 2)
                 )



sdc <- "gray30"
sc <- "gray10"


# # testing -----------------------------------------------------------------
# rayshader::plot_3d(heightmap = sites$achtriochtan$dem_matrix,
#                    hillshade = sites$achtriochtan$texture,
#                    baseshape = "circle",
#                    phi = settings$achtriochtan$phi,
#                    theta = settings$achtriochtan$theta,
#                    zscale = settings$achtriochtan$zscale,
#                    shadowcolor = sdc)
# 
# rayshader::plot_3d(heightmap = sites$easdale$dem_matrix,
#                    hillshade = sites$easdale$texture,
#                    baseshape = "circle",
#                    phi = settings$easdale$phi,
#                    theta = settings$easdale$theta, 
#                    zscale = settings$easdale$zscale,
#                    shadowcolor = sdc)
# 
# rayshader::plot_3d(heightmap = sites$kilmelford$dem_matrix,
#                    hillshade = sites$kilmelford$texture,
#                    baseshape = "circle",
#                    phi = settings$kilmelford$phi,
#                    theta = settings$kilmelford$theta, 
#                    zscale = settings$kilmelford$zscale, 
#                    shadowcolor = sdc)
# 
# rayshader::plot_3d(heightmap = sites$onich$dem_matrix,
#                    hillshade = sites$onich$texture,
#                    baseshape = "circle",
#                    phi = settings$onich$phi,
#                    theta = settings$onich$theta, 
#                    zscale = settings$onich$zscale,  
#                    shadowcolor = sdc)
# 
# rayshader::plot_3d(heightmap = sites$glenelg$dem_matrix,
#                    hillshade = sites$glenelg$texture,
#                    baseshape = "circle",
#                    phi = settings$glenelg$phi,
#                    theta = settings$glenelg$theta,
#                    zscale = settings$glenelg$zscale,
#                    fov = 45,
#                    zoom = 0.6,
#                    shadowcolor = sdc)
# 
# rayshader::plot_3d(heightmap = sites$uigg$dem_matrix,
#                    hillshade = sites$uigg$texture,
#                    baseshape = "circle",
#                    phi = settings$uigg$phi,
#                    theta = settings$uigg$theta,
#                    zscale = settings$uigg$zscale,
#                    shadowcolor = sdc)
# 
# rayshader::render_highquality(filename = 'test.png'
#                               # samples = 100,
#                               # lightintensity = 250)
# )


# plotting ----------------------------------------------------------------



purrr::iwalk(
    sites[2:6],
    function(x, i){
        
        # create viz
        rayshader::plot_3d(heightmap = x$dem_matrix,
                           hillshade = x$texture,
                           baseshape = "circle",
                           phi = settings[[i]]$phi,
                           zoom = 0.7,
                           theta = settings[[i]]$theta,
                           zscale = settings[[i]]$zscale,
                           shadowcolor = sdc)
        # save snapshot
        rayshader::render_snapshot(
            filename = sprintf("./out/figs/scotland_trip/%s.png", i),
            clear = TRUE,
            width = 2000,
            height = 2000,
            software_render = TRUE,
            cache_filename = sprintf("./out/cache/scotland_trip/%s.obj", i)
        )
        
    }         
)





# save --------------------------------------------------------------------


img_paths <- list.files("./out/figs/scotland_trip/",full.names = TRUE)

site_names <- img_paths %>% 
    fs::path_file() %>% 
    fs::path_ext_remove() %>%
    toupper()

imgs <- magick::image_read(img_paths) %>% 
    magick::image_border(color = "white", geometry = "50x15")

top <- magick::image_append(imgs[1:3])
bottom <- magick::image_append(imgs[4:6])

full <- magick::image_append(c(top, bottom), stack = TRUE) %>% 
    magick::image_border(color = "white", geometry = "0x450")

magick::image_write(image = full,
                    path = "./out/figs/scotland_trip/full.jpeg",
                    quality = 100)



dims <- magick::image_info(full)[ , c('height', 'width')]


# ybottom <- round(0.9*dims$height,0)
# # xbottom <- round(c(0.33-1/6, 0.66-1/6, 1-1/6) *dims$width, 0)
# xbottom <- round(50+c(0,1/3, 2/3) *dims$width, 0)
# 
# 
# extrafont::loadfonts(device = "win")
# full_proc <- full
# # 
# for(j in seq_along(xbottom)){
#     
#     full_proc <- magick::image_annotate(full_proc,
#                                         location = sprintf("+%d+%d", xbottom[j], ybottom),
#                                         text = site_names[j],
#                                         font = "Raleway",
#                                         size = 150)
#     
# }


xs <- rep(c(0.33-1/6, 0.66-1/6, 1-1/6), 2)
ys <- c(0.525, 0.035)

extrafont::loadfonts(device = "win")
extrafont::loadfonts(device = "postscript")
gp <- grid::gpar(fontfamily = "Fjalla One", fontsize = 18, col = "gray40")


img <- magick::image_draw(full, res = 300)


png(filename = "test.png", width = 3300, height = 2300, res = 72)
print(img)

for(j in seq_along(xs)){
    
    yi <- ifelse(j <= 3, 1, 2)
    
    
    grid::grid.text(gp = gp, 
                    label = site_names[j],
                    x = xs[j], 
                    y = ys[yi])
}
dev.off()









