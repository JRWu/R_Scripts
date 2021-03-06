#!/usr/bin/env Rscript 
options(error=recover)

library(ape)
library(phangorn)
library(vegan)
library(randomcoloR)

# commenting out incorrect clr dirichlet

# get default par
plotParameters <- par()

source("../UniFrac.r")

# read OTU table and format appropriately for input into UniFrac methods
breastmilk.otu.tab <- read.table("../data/breastmilk/td_OTU_tag_mapped_lineage.txt", header=T, sep="\t", row.names=1, comment.char="", check.names=FALSE)

#remove taxonomy column to make otu count matrix numeric
taxonomy <- breastmilk.otu.tab$taxonomy
breastmilk.otu.tab <- breastmilk.otu.tab[-length(colnames(breastmilk.otu.tab))]
breastmilk.otu.tab <- t(as.matrix(breastmilk.otu.tab))

#sort taxa from most to least abundant
taxaOrder <- rev(order(apply(breastmilk.otu.tab,2,sum)))
taxonomy <- taxonomy[taxaOrder]
breastmilk.otu.tab <- breastmilk.otu.tab[,taxaOrder]

# extract genus + species name from taxonomy
taxonomy <- as.character(taxonomy)
for (i in c(1:length(taxonomy))) {
  taxonomy[i] <- paste(strsplit(taxonomy[i],c(";"))[[1]][6],strsplit(taxonomy[i],c(";"))[[1]][7])
}

# rarefy before performing unweighted UniFrac
breastmilk.otu.tab.rarefy <- rrarefy(breastmilk.otu.tab, min(apply(breastmilk.otu.tab,1,sum)))

# read and root tree (rooted tree is required)
breastmilk.tree <- read.tree("../data/breastmilk/fasttree_all_seed_OTUs.tre")
breastmilk.tree <- midpoint(breastmilk.tree)

# read metadata
MyMeta<- read.table("../data/breastmilk/metadata.txt", header=T, sep="\t", row.names=1, comment.char="", check.names=FALSE)

#remove infected sample S38I
#MyMeta <- MyMeta[(which(rownames(MyMeta)!="S38I")),]

# filter OTU table and metadata so that only samples which appear in both are retained
otu_indicies <- match(rownames(MyMeta),rownames(breastmilk.otu.tab))
otu_indicies <- otu_indicies[!is.na(otu_indicies)]
breastmilk.otu.tab <- breastmilk.otu.tab[otu_indicies,]
MyMetaOrdered <- MyMeta[match(rownames(breastmilk.otu.tab),rownames(MyMeta)),]

unweighted <- getDistanceMatrix(breastmilk.otu.tab.rarefy,breastmilk.tree,method="unweighted",verbose=TRUE)

all_distance_matrices <- getDistanceMatrix(breastmilk.otu.tab,breastmilk.tree,method="all",verbose=TRUE)

weighted <- all_distance_matrices[["weighted"]]
information <- all_distance_matrices[["information"]]
ratio_no_log <- all_distance_matrices[["ratio_no_log"]]

# create bray curtis dist object using vegan, and turn into distance matrix
braycurtis.vegdist <- vegdist(breastmilk.otu.tab,method="bray")
braycurtis <- matrix(nrow=nrow(breastmilk.otu.tab),ncol=nrow(breastmilk.otu.tab))
braycurtis[lower.tri(braycurtis)] <- braycurtis.vegdist
diag(braycurtis) <- 0
braycurtis.vegdist <- vegdist(breastmilk.otu.tab,method="bray",upper=TRUE)
braycurtis[upper.tri(braycurtis)] <- braycurtis.vegdist

groups <- rep("Not Infected",length(MyMetaOrdered$Gestation))
groups[which(rownames(MyMetaOrdered)=="S38I")] <- "Infected"
groups <- as.factor(groups)

otuSum <- apply(breastmilk.otu.tab,1,sum)

# caculate pcoa vectors
unweighted.pcoa <- pcoa(unweighted)
weighted.pcoa <- pcoa(weighted)
information.pcoa <- pcoa(information)
ratio_no_log.pcoa <- pcoa(ratio_no_log)
braycurtis.pcoa <- list()
braycurtis.pcoa$vectors <- cmdscale(braycurtis,k=nrow(breastmilk.otu.tab)-1,add=TRUE)$points
rownames(braycurtis.pcoa$vectors) <- rownames(breastmilk.otu.tab)
colnames(braycurtis.pcoa$vectors) <- paste("Axis",c(1:ncol(braycurtis.pcoa$vectors)),sep='.')

# calculate total variance explained
unweighted.varExplained <- sum(apply(unweighted.pcoa$vector,2,function(x) sd(x)*sd(x)))
weighted.varExplained <- sum(apply(weighted.pcoa$vector,2,function(x) sd(x)*sd(x)))
information.varExplained <- sum(apply(information.pcoa$vector,2,function(x) sd(x)*sd(x)))
ratio_no_log.varExplained <- sum(apply(ratio_no_log.pcoa$vector,2,function(x) sd(x)*sd(x)))
braycurtis.varExplained <- sum(apply(braycurtis.pcoa$vector,2,function(x) sd(x)*sd(x)))

# calculate proportion of variance explained by First Coordinate
unweighted.pc1.varEx <- sd(unweighted.pcoa$vector[,1])*sd(unweighted.pcoa$vector[,1])/unweighted.varExplained
#calculate proportion of variance explained by Second Coordinate
unweighted.pc2.varEx <- sd(unweighted.pcoa$vector[,2])*sd(unweighted.pcoa$vector[,2])/unweighted.varExplained

weighted.pc1.varEx <- sd(weighted.pcoa$vector[,1])*sd(weighted.pcoa$vector[,1])/weighted.varExplained
weighted.pc2.varEx <- sd(weighted.pcoa$vector[,2])*sd(weighted.pcoa$vector[,2])/weighted.varExplained

information.pc1.varEx <- sd(information.pcoa$vector[,1])*sd(information.pcoa$vector[,1])/information.varExplained
information.pc2.varEx <- sd(information.pcoa$vector[,2])*sd(information.pcoa$vector[,2])/information.varExplained

ratio_no_log.pc1.varEx <- sd(ratio_no_log.pcoa$vector[,1])*sd(ratio_no_log.pcoa$vector[,1])/ratio_no_log.varExplained
ratio_no_log.pc2.varEx <- sd(ratio_no_log.pcoa$vector[,2])*sd(ratio_no_log.pcoa$vector[,2])/ratio_no_log.varExplained

braycurtis.pc1.varEx <- sd(braycurtis.pcoa$vector[,1])*sd(braycurtis.pcoa$vector[,1])/braycurtis.varExplained
braycurtis.pc2.varEx <- sd(braycurtis.pcoa$vector[,2])*sd(braycurtis.pcoa$vector[,2])/braycurtis.varExplained

#save plots as PDF
pdf("output/breastmilk_pcoa_plots.pdf")

# MAKE BAR PLOTS

#convert to dist structure
unweighted.dist <- as.dist(unweighted)
weighted.dist <- as.dist(weighted)
information.dist <- as.dist(information)
ratio_no_log.dist <- as.dist(ratio_no_log)
braycurtis.dist <- as.dist(braycurtis)

#"average" is most similar to UPGMA, apparently
unweighted.dendo <- hclust(unweighted.dist, method="average")
weighted.dendo <- hclust(weighted.dist, method="average")
information.dendo <- hclust(information.dist, method="average")
ratio_no_log.dendo <- hclust(ratio_no_log.dist, method="average")
braycurtis.dendo <- hclust(braycurtis.dist, method="average")

#get otu proportions for barplot
prop <- t(apply(breastmilk.otu.tab,1,function(x) x/sum(x)))

# plot dendogram with bar plots

par(mar=c(2,1,1,1)+0.1)
# generate taxa colors
colors <- distinctColorPalette(length(taxonomy))

layout(matrix(c(1,3,2,3),2,2, byrow=T), widths=c(6,4), height=c(4,4))
plot(unweighted.dendo, axes=F, ylab=NULL, ann=F, hang=-1,cex=0.5)
#order the barplot 
barplot(t(prop[unweighted.dendo$order,]), space=0,col=colors, las=2, cex.names=0.5)
plot(1,2, pch = 1, lty = 1, ylim=c(-20,20), type = "n", axes = FALSE, ann = FALSE)
legend(x="center", legend=taxonomy, col=colors, lwd=5, cex=.5, border=NULL,ncol=2)

layout(matrix(c(1,3,2,3),2,2, byrow=T), widths=c(6,4), height=c(4,4))
plot(weighted.dendo, axes=F, ylab=NULL, ann=F, hang=-1,cex=0.5)
barplot(t(prop[weighted.dendo$order,]), space=0,col=colors, las=2, cex.names=0.5)
plot(1,2, pch = 1, lty = 1, ylim=c(-20,20), type = "n", axes = FALSE, ann = FALSE)
legend(x="center", legend=taxonomy, col=colors, lwd=5, cex=.5, border=NULL,ncol=2)

layout(matrix(c(1,3,2,3),2,2, byrow=T), widths=c(6,4), height=c(4,4))
plot(information.dendo, axes=F, ylab=NULL, ann=F, hang=-1,cex=0.5)
barplot(t(prop[information.dendo$order,]), space=0,col=colors, las=2, cex.names=0.5)
plot(1,2, pch = 1, lty = 1, ylim=c(-20,20), type = "n", axes = FALSE, ann = FALSE)
legend(x="center", legend=taxonomy, col=colors, lwd=5, cex=.5, border=NULL,ncol=2)

layout(matrix(c(1,3,2,3),2,2, byrow=T), widths=c(6,4), height=c(4,4))
plot(ratio_no_log.dendo, axes=F, ylab=NULL, ann=F, hang=-1,cex=0.5)
barplot(t(prop[ratio_no_log.dendo$order,]), space=0,col=colors, las=2, cex.names=0.5)
plot(1,2, pch = 1, lty = 1, ylim=c(-20,20), type = "n", axes = FALSE, ann = FALSE)
legend(x="center", legend=taxonomy, col=colors, lwd=5, cex=.5, border=NULL,ncol=2)

layout(matrix(c(1,3,2,3),2,2, byrow=T), widths=c(6,4), height=c(4,4))
plot(braycurtis.dendo, axes=F, ylab=NULL, ann=F, hang=-1,cex=0.5)
barplot(t(prop[braycurtis.dendo$order,]), space=0,col=colors, las=2, cex.names=0.5)
plot(1,2, pch = 1, lty = 1, ylim=c(-20,20), type = "n", axes = FALSE, ann = FALSE)
legend(x="center", legend=taxonomy, col=colors, lwd=5, cex=.5, border=NULL,ncol=2)

par(plotParameters)



#choose colors for each condition
palette(c("red","black","cyan","dodgerblue","blue","orange"))

#plot pcoa plots with legend
plot(unweighted.pcoa$vectors[,1],unweighted.pcoa$vectors[,2], type="p",col=groups,main="Unweighted UniFrac\nprincipal coordinate analysis",xlab=paste("First Coordinate", round(unweighted.pc1.varEx,digits=3),"variance explained"),ylab=paste("Second Coordinate", round(unweighted.pc2.varEx,digits=3),"variance explained"),pch=19,cex.lab=1.4,cex.main=2)
#placement with S38I included
#legend(-0.1,-0.055,levels(groups),col=palette(),pch=19)
# #placement with S38I excluded
# legend(0.055,0.15,levels(groups),col=palette(),pch=19)

plot(weighted.pcoa$vectors[,1],weighted.pcoa$vectors[,2], col=groups,main="Weighted UniFrac\nprincipal coordinate analysis",xlab=paste("First Coordinate", round(weighted.pc1.varEx,digits=3),"variance explained"),ylab=paste("Second Coordinate", round(weighted.pc2.varEx,digits=3),"variance explained"),pch=19,cex.lab=1.4,cex.main=2)
#legend(-0.1,-0.12,levels(groups),col=palette(),pch=19)

plot(information.pcoa$vectors[,1],information.pcoa$vectors[,2], col=groups,main="Information UniFrac\nprincipal coordinate analysis",xlab=paste("First Coordinate", round(information.pc1.varEx,digits=3),"variance explained"),ylab=paste("Second Coordinate", round(information.pc2.varEx,digits=3),"variance explained"),pch=19,cex.lab=1.4,cex.main=2)
#placement with S38I included
#legend(-0.15,-0.4,levels(groups),col=palette(),pch=19)
# #placement with S38I excluded
# legend(0.4,-0.15,levels(groups),col=palette(),pch=19)

plot(ratio_no_log.pcoa$vectors[,1],ratio_no_log.pcoa$vectors[,2], col=groups,main="Ratio UniFrac\nprincipal coordinate analysis",xlab=paste("First Coordinate", round(ratio_no_log.pc1.varEx,digits=3),"variance explained"),ylab=paste("Second Coordinate", round(ratio_no_log.pc2.varEx,digits=3),"variance explained"),pch=19,cex.lab=1.4,cex.main=2)

plot(braycurtis.pcoa$vectors[,1],braycurtis.pcoa$vectors[,2], col=groups,main="Bray Curtis Dissimilarity\nprincipal coordinate analysis",xlab=paste("First Coordinate", round(braycurtis.pc1.varEx,digits=3),"variance explained"),ylab=paste("Second Coordinate", round(braycurtis.pc2.varEx,digits=3),"variance explained"),pch=19,cex.lab=1.4,cex.main=2)

dev.off()
