#!/usr/bin/Rscript

## FOR GG
# Plots a set of 30 tongue samples vs 30 tongue samples
# Should be no differences, but there's a difference in the sets of 
library(vegan)
library(phangorn)
source("GUniFrac.R")

# read data
original.tongue.data <- read.table("../../data/tongue_dorsum/tongue_vs_tongue_30_forR.txt",sep="\t",check.names=FALSE,quote="",comment.char="", header=TRUE,row.names=1)
tongue.tree <- read.tree("../../data/tongue_dorsum/tongue_vs_tongue.tre")
original.tongue.cheek.data <- read.table("../../data/tongue_dorsum_vs_buccal_mucosa/hmp_tongue_cheek_data.txt",sep="\t",check.names=FALSE,quote="",comment.char="", header=TRUE,row.names=1)
tongue.cheek.tree <- read.tree("../../data/tongue_dorsum_vs_buccal_mucosa/hmp_tongue_cheek_subtree.tre")

# remove all OTUs with less than 100 counts across all samples
tongue.otu.sum <- apply(original.tongue.data,1,sum)
original.tongue.data <- original.tongue.data[which(tongue.otu.sum >= 100),]
tongue.otu.sum <- tongue.otu.sum[which(tongue.otu.sum>= 100)]

tongue.cheek.otu.sum <- apply(original.tongue.cheek.data,1,sum)
original.tongue.cheek.data <- original.tongue.cheek.data[which(tongue.cheek.otu.sum >= 100),]
tongue.cheek.otu.sum <- tongue.cheek.otu.sum[which(tongue.cheek.otu.sum>= 100)]

# make sure tree tip names match OTU names by taking out single quotes
tongue.tree$tip.label <- gsub("'","",tongue.tree$tip.label)
tongue.cheek.tree$tip.label <- gsub("'","",tongue.cheek.tree$tip.label)

# remove OTUs that are not in the tree
original.tongue.data <- original.tongue.data[which(rownames(original.tongue.data) %in% tongue.tree$tip.label),]
original.tongue.cheek.data <- original.tongue.cheek.data[which(rownames(original.tongue.cheek.data) %in% tongue.cheek.tree$tip.label),]

original.tongue.data <- t(original.tongue.data)
original.tongue.cheek.data <- t(original.tongue.cheek.data)

# remove extra taxa from tree
absent <- tongue.tree$tip.label[!(tongue.tree$tip.label %in% colnames(original.tongue.data))]
if (length(absent) != 0) {
		tongue.tree <- drop.tip(tongue.tree, absent)
}
absent <- tongue.cheek.tree$tip.label[!(tongue.cheek.tree$tip.label %in% colnames(original.tongue.cheek.data))]
if (length(absent) != 0) {
		tongue.cheek.tree <- drop.tip(tongue.cheek.tree, absent)
}

# root tree (rooted tree is required)
tongue.tree <- midpoint(tongue.tree)
tongue.cheek.tree <- midpoint(tongue.cheek.tree)

# tongue and cheek data have more read counts per sample, so we're rarefying to the lowest number of per sample counts in tongue only data
d.tongue.data <- rrarefy(original.tongue.data, min(apply(original.tongue.data,1,sum)))
e.tongue.data <- rrarefy(original.tongue.data, min(apply(original.tongue.data,1,sum)))

d.tongue.cheek.data <- rrarefy(original.tongue.cheek.data, min(apply(original.tongue.data,1,sum)))
e.tongue.cheek.data <- rrarefy(original.tongue.cheek.data, min(apply(original.tongue.data,1,sum)))

d.tongue.otu.sum <- apply(d.tongue.data,2,sum)
d.tongue.data <- d.tongue.data[,which(d.tongue.otu.sum > 0)]
d.tongue.tree <- tongue.tree
absent <- d.tongue.tree$tip.label[!(d.tongue.tree$tip.label %in% colnames(d.tongue.data))]
if (length(absent) != 0) {
		d.tongue.tree <- drop.tip(d.tongue.tree, absent)
}

e.tongue.otu.sum <- apply(e.tongue.data,2,sum)
e.tongue.data <- e.tongue.data[,which(e.tongue.otu.sum > 0)]
e.tongue.tree <- tongue.tree
absent <- e.tongue.tree$tip.label[!(e.tongue.tree$tip.label %in% colnames(e.tongue.data))]
if (length(absent) != 0) {
		e.tongue.tree <- drop.tip(e.tongue.tree, absent)
}

d.tongue.cheek.otu.sum <- apply(d.tongue.cheek.data,2,sum)
d.tongue.cheek.data <- d.tongue.cheek.data[,which(d.tongue.cheek.otu.sum > 0)]
d.tongue.cheek.tree <- tongue.cheek.tree
absent <- d.tongue.cheek.tree$tip.label[!(d.tongue.cheek.tree$tip.label %in% colnames(d.tongue.cheek.data))]
if (length(absent) != 0) {
		d.tongue.cheek.tree <- drop.tip(d.tongue.cheek.tree, absent)
}

e.tongue.cheek.otu.sum <- apply(e.tongue.cheek.data,2,sum)
e.tongue.cheek.data <- e.tongue.cheek.data[,which(e.tongue.cheek.otu.sum > 0)]
e.tongue.cheek.tree <- tongue.cheek.tree
absent <- e.tongue.cheek.tree$tip.label[!(e.tongue.cheek.tree$tip.label %in% colnames(e.tongue.cheek.data))]
if (length(absent) != 0) {
		e.tongue.cheek.tree <- drop.tip(e.tongue.cheek.tree, absent)
}

alphas <- c(0, 0.25, 0.5, 0.75, 1)

d.tongue.unifrac <- GUniFrac(d.tongue.data,d.tongue.tree, alpha = alphas)
e.tongue.unifrac <- GUniFrac(e.tongue.data,e.tongue.tree, alpha = alphas)
d.tongue.cheek.unifrac <- GUniFrac(d.tongue.cheek.data,d.tongue.cheek.tree, alpha = alphas)
e.tongue.cheek.unifrac <- GUniFrac(e.tongue.cheek.data,e.tongue.cheek.tree, alpha = alphas)

d.tongue <- list()
e.tongue <- list()
d.tongue.cheek <- list()
e.tongue.cheek <- list()

alphas <- c(alphas,"d_UW")

for (i in c(1:length(alphas))) {
	d.tongue[[as.character(alphas[i])]] <- pcoa(d.tongue.unifrac$unifracs[,,i])
	e.tongue[[as.character(alphas[i])]] <- pcoa(e.tongue.unifrac$unifracs[,,i])
	d.tongue.cheek[[as.character(alphas[i])]] <- pcoa(d.tongue.cheek.unifrac$unifracs[,,i])
	e.tongue.cheek[[as.character(alphas[i])]] <- pcoa(e.tongue.cheek.unifrac$unifracs[,,i])
}

#function to get variance explained for the PCOA component labels
getVarExplained <- function(vector) {
	rawVarEx <- apply(vector,2,function(x) sd(x)*sd(x))
	totalVarExplained <- sum(rawVarEx)
	varEx <- rawVarEx/totalVarExplained
	return(varEx)
}

plotMigration <- function(d,e) {
	d.varEx <- getVarExplained(d$vectors)
	# convert to percentage
	d.varEx <- d.varEx * 100

	# Setup axis labelling conventions
	per <- "%"
	x.pc1.explained <- d.varEx[1]
	x.pc1.explained <- round(x.pc1.explained, digits=1)
	xlabel <- "Principal Component1 Eigenvalues: "
	xla <- paste(xlabel, x.pc1.explained,per, sep="", collapse=NULL)

	x.pc2.explained <- d.varEx[2]
	x.pc2.explained <- round(x.pc2.explained, digits=1)
	ylabel <- "Principal Component2 Eigenvalues: "
	yla <- paste(ylabel, x.pc2.explained,per, sep="", collapse=NULL)

	#perform procrustes fit
	fit <- procrustes(d$vectors, e$vectors)

	rtl <- NULL
	ltr <- NULL

	component <- 1

	for (i in 1:60)	# Iterate through all 60 samples
	{
		if ( (d$vectors[i,component] > 0) & (fit$Yrot[i,component] < 0))
		{	
			print("Right Cluster to Left Cluster Movement: ")	# Moved from right to left
			print(rownames(d$vectors)[i])
			rtl <- c(rtl, rownames(d$vectors)[i])	# Get list of Right to Left Movement
		}	
	}
	for (i in 1:60)
	{
		if ( (d$vectors[i,component] < 0) & (fit$Yrot[i,component] > 0))
		{
			print("Left Cluster to Right Cluster Movement: ")	# Moved from left to right
			print(rownames(d$vectors)[i])
			ltr <- c(ltr, rownames(d$vectors)[i])	# Get list of Left to Right movement
		}
	}

	# First/second refer to the columns the data is being read from 
	first <- 1
	second <- 2

	plot(d$vectors[1:60,first], d$vectors[1:60,second],main="Sample Migration between Rarefactions",xlab=xla,ylab=yla, pch=19, col=rgb(0,0,0,0.4))	# Plot the 1st rarefation

	shapes <- c(19,15,19,15,19)
	colours <- c(rgb(1,0,0,0.4), rgb(1,0,0,0.4), rgb(0,0,1,0.4), rgb(0,0,1,0.4), rgb(0,0,0,0.4) )

	#legend(x=-0.25,y=0.31,title="Sample Movement", legend = c("Left->Right","Origin","Right->Left","Origin", "No Change"), pch=shapes, col=colours)

	# Points that have moved from right to left are red
	# Points that have moved from left to right are blue

	# Points represent a plot of Rarefaction 1, but are coloured based on sample movement of Rare 2
	points(d$vectors[rtl,first][fit$Yrot[rtl,first] < 0], d$vectors[rtl,second][fit$Yrot[rtl,first] < 0], pch=19, col=rgb(1,0,0,0.4))	# Red
	points(d$vectors[ltr,first][fit$Yrot[ltr,first] > 0], d$vectors[ltr,second][fit$Yrot[ltr,first] > 0], pch=19, col=rgb(0,0,1,0.4))	# Blue

	# The squares indicate WHERE they have moved from 
	# Can comment this out to remove square drawing
	points(fit$Yrot[rtl,first], fit$Yrot[rtl,second], pch = 15, col=rgb(1,0,0,0.4))
	points(fit$Yrot[ltr,first], fit$Yrot[ltr,second], pch = 15, col=rgb(0,0,1,0.4))

	# Draw line segments between the movements
	arrows(fit$Yrot[rtl,first], fit$Yrot[rtl, second], d$vectors[rtl, first], d$vectors[rtl, second], col = rgb(1,0,0,0.5), length=0.1)

	arrows(fit$Yrot[ltr,first], fit$Yrot[ltr, second], d$vectors[ltr, first], d$vectors[ltr, second], col = rgb(0,0,1,0.5), length=0.1)
}



pdf("UniFrac_tvst_movement_GUniFrac.pdf")	# Comment out if not plotting

for (i in c(1:length(alphas))) {
	plotMigration(d.tongue[[as.character(alphas[i])]],e.tongue[[as.character(alphas[i])]])
	plotMigration(d.tongue.cheek[[as.character(alphas[i])]], e.tongue.cheek[[as.character(alphas[i])]])
	par(new=TRUE)
	plot(d.tongue.cheek[[as.character(alphas[i])]]$vectors[1:60,1], d.tongue.cheek[[as.character(alphas[i])]]$vectors[1:60,2], xlab="",ylab="",pch=19, col=c(rep("black",30),rep("red",30)))	# Plot the 1st rarefation
}



dev.off()







