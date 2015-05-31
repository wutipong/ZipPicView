package com.playground_soft.zippicviewdsk

import java.awt.BorderLayout
import java.awt.FlowLayout
import java.io.File
import java.io.FileOutputStream
import javax.imageio.ImageIO
import javax.swing.ImageIcon
import javax.swing.JButton
import javax.swing.JFileChooser
import javax.swing.JLabel
import javax.swing.JPanel
import javax.swing.JScrollPane
import javax.swing.JTabbedPane
import org.apache.commons.compress.archivers.zip.ZipArchiveEntry
import org.apache.commons.compress.archivers.zip.ZipFile

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

	val JLabel imageLabel
	val int tabIndex

	val JFileChooser fileChooser
	
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

		imageLabel = new JLabel

		layout = new BorderLayout

		add(new JPanel => [
			layout = new FlowLayout
			add(previousButton)
			add(nextButton)
			add(saveButton)
			add(closeButton)
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
		var image = ImageIO.read(inputStream)
		inputStream.close

		imageLabel.icon = new ImageIcon(image)
		imageLabel.invalidate
		imageLabel.repaint

		filenameLabel.text = entry.name
		
		tab.setTitleAt(
			tabIndex,
			extractFileName(entry)
		)
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