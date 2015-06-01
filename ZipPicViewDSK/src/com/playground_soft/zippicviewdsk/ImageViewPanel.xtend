package com.playground_soft.zippicviewdsk

import java.awt.BorderLayout
import java.awt.FlowLayout
import java.awt.image.BufferedImage
import java.io.File
import java.io.FileOutputStream
import javax.imageio.ImageIO
import javax.swing.ImageIcon
import javax.swing.JButton
import javax.swing.JFileChooser
import javax.swing.JLabel
import javax.swing.JPanel
import javax.swing.JScrollPane
import javax.swing.JSpinner
import javax.swing.JTabbedPane
import javax.swing.SpinnerNumberModel
import org.apache.commons.compress.archivers.zip.ZipArchiveEntry
import org.apache.commons.compress.archivers.zip.ZipFile
import org.imgscalr.Scalr
import org.imgscalr.Scalr.Method
import org.imgscalr.Scalr.Mode

class ImageViewPanel extends JPanel {
	val ZipFile zipFile
	val ZipArchiveEntry[] zipEntries
	int imageIndex
	val JTabbedPane tab

	val JButton nextButton
	val JButton previousButton
	val JLabel filenameLabel
	val JButton saveButton
	val JButton closeButton

	val JSpinner zoomSpinner
	
	val JLabel imageLabel
	val int tabIndex

	val JFileChooser fileChooser
	
	var BufferedImage originalImage
	
	new(JTabbedPane tab, ZipFile zipFile, ZipArchiveEntry[] zipEntries, int index) {
		this.tab = tab
		this.zipFile = zipFile
		this.zipEntries = zipEntries

		nextButton = new JButton("Next") => [
			addActionListener[setImageIndex(imageIndex + 1)]
		]
		previousButton = new JButton("Prev") => [
			addActionListener[setImageIndex(imageIndex - 1)]
		]
		filenameLabel = new JLabel
		closeButton = new JButton("Close") => [
			addActionListener[tab.remove(this)]
		]
		saveButton = new JButton("Save As") => [
			addActionListener[save]
		]
		
		zoomSpinner = new JSpinner(	new SpinnerNumberModel(1.0, 0.01, 1.0, 0.1)) =>[
			addChangeListener([
				val zoom = zoomSpinner.value as Double
				val width = originalImage.width * zoom
				val height = originalImage.height * zoom
				
				updateImage(width as int, height as int)
			])
			editor = new JSpinner.NumberEditor(it, "###%")
		]
		imageLabel = new JLabel

		layout = new BorderLayout

		add(new JPanel => [
			layout = new FlowLayout
			add(previousButton)
			add(nextButton)
			add(saveButton)
			add(closeButton)
			add(zoomSpinner)
		], BorderLayout.NORTH)

		add(new JScrollPane(imageLabel), BorderLayout.CENTER)

		add(filenameLabel, BorderLayout.SOUTH)

		tabIndex = tab.tabCount
		tab.add(this)
		tab.selectedIndex = tabIndex
		
		fileChooser = new JFileChooser
		setImageIndex(index)
	}

	def setImageIndex(int index) {
		val entry = zipEntries.get(index)
		imageIndex = index

		previousButton.enabled = imageIndex != 0
		nextButton.enabled = imageIndex != zipEntries.length - 1

		var inputStream = zipFile.getInputStream(entry)
		originalImage = ImageIO.read(inputStream)
		inputStream.close

		zoomSpinner.value = 1.00
		
		updateImage(originalImage.width, originalImage.height)
		
		filenameLabel.text = '''«entry.name» - [«originalImage.width» x «originalImage.height»]''' 
		
		tab.setTitleAt(
			tabIndex,
			extractFileName(entry)
		)
	}
	
	def updateImage(int width, int height){
		val image = Scalr.resize(originalImage, Method.QUALITY, Mode.AUTOMATIC, width, height)
		imageLabel.icon = new ImageIcon(image)	
		imageLabel.invalidate
		imageLabel.repaint
	}
	
	def save() {
		val entry = zipEntries.get(imageIndex)
		
		fileChooser.selectedFile = new File(extractFileName(entry))
		if (fileChooser.showSaveDialog(this) != JFileChooser.APPROVE_OPTION)
			return

		val reader = zipFile.getInputStream(entry)
		val writer = new FileOutputStream(fileChooser.selectedFile)

		val buffer = newByteArrayOfSize(4096)
		var readCount = 0
		while ((readCount = reader.read(buffer)) > 0) {
			writer.write(buffer, 0, readCount)
		}

		reader.close
		writer.close
	}
	
	static def extractFileName(ZipArchiveEntry entry) {
		val lastSlash = entry.name.lastIndexOf('/')
		if(lastSlash >=0) entry.name.substring(lastSlash + 1)
		else entry.name
	}
}