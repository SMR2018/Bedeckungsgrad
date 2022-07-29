# BEdeckungsgraf-Funktion fuer batch-Verarbeitung:
# Autorin: Samantha Rubo
# Datum: 05.04.2022




batch_bedeckungsgrad <- function(image_in_path,
                                 image_in_resized_path,
                                 image_in_file, 
                                 image_out_path, 
                                 image_out_file,
                                 t1 = 0.2,
                                 brighten_dark_spots = FALSE){
    
    library(dplyr)
    library(jpeg)
    library(raster)
    library(tidyr)
    
    
    ##########################################################################
    ############  1. Bild einlesen und downsamplen     #######################
    ##########################################################################
    img <- readJPEG(paste0(image_in_path, image_in_file))
    #resize image to width = 100 pixels
    imgDm <- dim(img)
    height1 <- 300
    width1 <- floor(imgDm[2]/imgDm[1]*height1)
    img2 <- OpenImageR::resizeImage(img, width = height1, height = width1, 
                                    method = "nearest", 
                                    normalize_pixels = TRUE) #sRGB color 
    
    #Workspace aufräumen:
    rm(img)
    gc()
    
    
    ##########################################################################
    ############  1.b Dunkle Stellen aufhellen (bei großen Pflanzen) #########
    ##########################################################################
    # Gamma-Korrektur:
    # img2 <- if(brighten_dark_spots == TRUE) {
    #     OpenImageR::gamma_correction(img2, gamma = 2)} else{
    #         img2}
    
    
    #Dunkle Bereiche transformieren:
    dark_to_light_green <- function(image){
    #Auswahl der dunklen Bereiche im grünen Kanal:
    idx2 <- image[,,2] < 0.4
    
    #Daten transformieren:
    x <- (image[,,2][idx2])^(1/3)
    x <- scales::rescale(x, to = c(0,0.4))
    image[,,2][idx2] <- x
    image
    }
    img2 <- if(brighten_dark_spots == TRUE) {
        dark_to_light_green(image = img2)} else{
            img2}
    
    
    ##########################################################################
    ############  2. excess green (ExG) berechnen      #######################
    ##########################################################################
    #excess green index (ExG = 2 g - r-b)
    ExG <- 2*img2[,,2] - img2[,,1] - img2[,,3] #von sRGB, nicht von Normalisiertem Bild!
    
    #Otsu threshold: in 0 und 1 umwandeln (planze/keine pflanze
    ExG_Otsu <- ifelse(ExG < t1,0,255)
    
    ##########################################################################
    ############  3. Bedeckungsgrad berechnen:  ##############################
    ##########################################################################
    Bedeckungsgrad_table <- table(ExG_Otsu)
    probs <- prop.table(Bedeckungsgrad_table) *100 
    Bedeckungsgrad <- round(probs[[ "255"]],2)
    cat("Bedeckungsgrad:", Bedeckungsgrad, "%")
    
    ##########################################################################
    ############  4. Grafiken speichern:  ####################################
    ##########################################################################
    jpeg(filename = paste0(image_out_path, image_out_file), 
         width = width1, height = height1)
    OpenImageR::imageShow(ExG_Otsu) #ExG_Otsu
    dev.off()

    jpeg(filename = paste0(image_in_resized_path,
                           tools::file_path_sans_ext(image_in_file), 
                           "_resized.jpeg"),
         width = width1, height = height1)
    OpenImageR::imageShow(img2) #ExG_Otsu
    dev.off()
    
    ##########################################################################
    ############  5. Objekt ausgeben      ####################################
    ##########################################################################
    data.frame(Pfad = image_in_path, 
               Bild = image_in_file, 
               Bedeckungsgrad_prozent = Bedeckungsgrad)
}