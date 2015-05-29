package com.playground_soft.zippicviewdsk

import java.awt.BorderLayout
import java.awt.FlowLayout
import javax.imageio.ImageIO
import javax.swing.ImageIcon
import javax.swing.JButton
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

	val JButton next
	val JButton prev
	val JLabel filename
	val JButton close

	val JLabel label
	val int tabIndex

	new(JTabbedPane tab, ZipFile zipFile, ZipArchiveEntry[] zipEntries, int index) {
		this.tab = tab
		this.zipFile = zipFile
		this.zipEntries = zipEntries

		next = new JButton("Next") => [
			addActionListener[setImageIndex(imageIndex + 1)]
		]
		prev = new JButton("Prev") => [
			addActionListener[setImageIndex(imageIndex - 1)]
		]
		filename = new JLabel
		close = new JButton("Close") => [
			addActionListener[tab.remove(this)]
		]

		label = new JLabel

		layout = new BorderLayout

		add(new JPanel => [
			layout = new FlowLayout
			add(prev)
			add(next)
			add(close)
		], BorderLayout.NORTH)

		add(new JScrollPane(label), BorderLayout.CENTER)

		add(filename, BorderLayout.SOUTH)

		tabIndex = tab.tabCount
		tab.add(this)
		tab.selectedIndex = tabIndex

		setImageIndex(index)
	}

	def setImageIndex(int index) {
		val entry = zipEntries.get(index)
		imageIndex = index

		prev.enabled = imageIndex != 0
		next.enabled = imageIndex != zipEntries.length - 1

		var inputStream = zipFile.getInputStream(entry)
		var image = ImageIO.read(inputStream)

		label.icon = new ImageIcon(image)
		label.invalidate
		label.repaint

		filename.text = entry.name
		val slashIndex = entry.name.indexOf('/')
		tab.setTitleAt(
			tabIndex,
			if(slashIndex > 0) entry.name.substring(slashIndex + 1) else entry.name
		)
	}
}