package com.playground_soft.zippicviewdsk

import com.playground_soft.zippicviewdsk.MainFrame.TreeItemText
import com.playground_soft.zippicviewdsk.MainFrame.UpdateThumnailWorker
import java.awt.BorderLayout
import java.awt.Dimension
import java.awt.GridLayout
import java.awt.Image
import java.awt.event.MouseEvent
import java.io.File
import java.util.ArrayList
import java.util.Collections
import java.util.List
import javax.imageio.ImageIO
import javax.swing.ImageIcon
import javax.swing.JButton
import javax.swing.JDialog
import javax.swing.JFileChooser
import javax.swing.JFrame
import javax.swing.JLabel
import javax.swing.JPanel
import javax.swing.JProgressBar
import javax.swing.JScrollPane
import javax.swing.JSplitPane
import javax.swing.JTabbedPane
import javax.swing.JTree
import javax.swing.SwingUtilities
import javax.swing.SwingWorker
import javax.swing.UIManager
import javax.swing.WindowConstants
import javax.swing.border.TitledBorder
import javax.swing.event.MouseInputAdapter
import javax.swing.filechooser.FileFilter
import javax.swing.tree.DefaultMutableTreeNode
import javax.swing.tree.DefaultTreeModel
import javax.swing.tree.TreeSelectionModel
import org.apache.commons.compress.archivers.zip.ZipArchiveEntry
import org.apache.commons.compress.archivers.zip.ZipFile
import org.eclipse.xtend.lib.annotations.Data
import org.imgscalr.Scalr

import static javax.swing.UIManager.*

class MainFrame extends JFrame {
	static def main(String [] args) {
		SwingUtilities.invokeLater [
			UIManager.lookAndFeel = "org.pushingpixels.substance.api.skin.SubstanceTwilightLookAndFeel"
			new MainFrame().visible = true
		]

		return;
	}

	File file = null
	ZipFile zipFile = null
	ZipArchiveEntry[] fileEntries = null

	final JTree tree
	final JPanel previewPanel
	final JProgressBar progressBar

	final JTabbedPane tab
	UpdateThumnailWorker worker

	new() {
		super("ZipPicView")

		tree = new JTree => [
			selectionModel.selectionMode = TreeSelectionModel.SINGLE_TREE_SELECTION
			addTreeSelectionListener[onTreeItemSelected]

			model = new DefaultTreeModel(new DefaultMutableTreeNode(new TreeItemText("/", "")))
			preferredSize = new Dimension(400, 500)

		]
		previewPanel = new JPanel => [
			layout = new GridLayout(0, 5, 5, 5)
		]

		progressBar = new JProgressBar => [
			enabled = false
		]

		tab = new JTabbedPane => [
			addTab("Browser", new JPanel => [
				layout = new BorderLayout
				add(new JSplitPane => [
					add(
						new JPanel => [
							layout = new BorderLayout
							add(new JButton("Open") => [
								addActionListener([openFile])
							], BorderLayout.NORTH)
							add(new JScrollPane(tree), BorderLayout.CENTER)
						],
						JSplitPane.LEFT
					)
					add(new JScrollPane(previewPanel), JSplitPane.RIGHT)
				], BorderLayout.CENTER)

				add(progressBar, BorderLayout.SOUTH)
			])
		]

		contentPane => [
			layout = new BorderLayout
			add(tab, BorderLayout.CENTER)
		]

		minimumSize = new Dimension(1024, 768)
		defaultCloseOperation = EXIT_ON_CLOSE
	}

	def DefaultMutableTreeNode addTreeNode(ArrayList<DefaultMutableTreeNode> nodeList, String path) {
		var node = nodeList.findFirst [
			var item = it.userObject as TreeItemText
			item.path == path
		]

		if (node != null) {
			return node
		}

		val lastSlashStripped = path.substring(0, path.length - 1)
		val newLastSlashIndex = lastSlashStripped.lastIndexOf('/')

		val parentPath = if (newLastSlashIndex > 0) {
				lastSlashStripped.substring(0, newLastSlashIndex + 1)
			} else {
				""
			}

		val name = lastSlashStripped.substring(newLastSlashIndex + 1)
		val parent = addTreeNode(nodeList, parentPath)

		node = new DefaultMutableTreeNode
		node.userObject = new TreeItemText(name, path)
		parent.add(node)
		nodeList.add(node)

		return node
	}

	def openFile() {
		val fileChooser = new JFileChooser => [
			selectedFile = file
			fileFilter = new FileFilter {
				override accept(File file) {
					file.isDirectory || file.name.endsWith(".zip")
				}

				override getDescription() {
					"Zip Files"
				}
			}

		]
		if (fileChooser.showOpenDialog(this) != JFileChooser.APPROVE_OPTION)
			return if(worker != null) worker.cancel(true)
		if(zipFile != null) zipFile.close

		while (tab.tabCount != 1)
			tab.removeTabAt(1)

		val dialog = new JDialog(this, true) => [
			title = "Loading"
			defaultCloseOperation = WindowConstants.DO_NOTHING_ON_CLOSE
			contentPane => [
				layout = new BorderLayout
				add(new JLabel("Processing File"), BorderLayout.CENTER)
				add(new JProgressBar => [
					indeterminate = true
				], BorderLayout.SOUTH)
			]
			pack
			locationRelativeTo = this
		]

		val filterWorker = new SwingWorker<Void, Void> {
			override protected doInBackground() throws Exception {
				file = fileChooser.selectedFile
				zipFile = new ZipFile(file.absolutePath)

				val preFilterList = Collections.list(zipFile.entries)
				fileEntries = preFilterList.filter [
					it.isDirectory || it.name.endsWith(".jpg") || it.name.endsWith(".jpeg") || it.name.endsWith(".png")
				]
				return null
			}

			override protected done() {
				dialog.visible = false

				var treeNodeList = new ArrayList<DefaultMutableTreeNode>
				var rootNode = new DefaultMutableTreeNode(new TreeItemText("/", ""))
				treeNodeList.add(rootNode)

				for (entry : fileEntries) {
					if (entry.isDirectory) {
						var name = entry.name
						addTreeNode(treeNodeList, name)
					}
				}

				tree.model = new DefaultTreeModel(rootNode)
				tree.selectionRow = 0

				title = '''ZipPicView - «fileChooser.selectedFile.name»'''

			}
		}
		filterWorker.execute
		dialog.visible = true
	}

	def onTreeItemSelected() {
		progressBar.value = 0
		
		if (zipFile == null) {
			return
		}

		if(worker != null) worker.cancel(true)
		val node = tree.lastSelectedPathComponent as DefaultMutableTreeNode
		if(node == null) return

		val path = (node.userObject as TreeItemText).path

		val childFileEntry = fileEntries.filter [
			if(it.isDirectory) return false
			if(!it.name.startsWith(path)) return false
			if(it.name.substring(path.length).contains('/')) return false

			return true
		].sortWith [ ZipArchiveEntry entry1, ZipArchiveEntry entry2 |
			return entry1.name.compareTo(entry2.name)
		]

		previewPanel.removeAll

		for (var i = 0; i < childFileEntry.length; i++) {
			val child = childFileEntry.get(i)
			val index = i

			previewPanel.add(new JLabel => [
				border = new TitledBorder(child.name.substring(path.length)) => [
					titlePosition = TitledBorder.ABOVE_BOTTOM
				]
				minimumSize = new Dimension(250, 250)
				preferredSize = new Dimension(250, 250)

				addMouseListener(new MouseInputAdapter() {
					override mouseClicked(MouseEvent e) {
						if (e.clickCount == 2) {
							new ImageViewPanel(tab, zipFile, childFileEntry, index)
						}
					}
				})
			])
		}

		previewPanel.revalidate
		previewPanel.repaint

		worker = new UpdateThumnailWorker(progressBar, previewPanel, childFileEntry, zipFile)
		worker.execute
	}

	@Data
	static class TreeItemText {
		String name
		String path

		override toString() {
			return name
		}
	}

	@Data
	static class ImageEntry {
		int index
		Image image
	}

	static class UpdateThumnailWorker extends SwingWorker<Void, ImageEntry> {
		val JProgressBar progressBar
		val JPanel previewPanel
		val ZipArchiveEntry[] fileEntry
		val ZipFile file

		new(JProgressBar progressBar, JPanel previewPanel, ZipArchiveEntry[] fileEntry, ZipFile file) {
			this.progressBar = progressBar
			this.previewPanel = previewPanel
			this.fileEntry = fileEntry
			this.file = file

			progressBar.minimum = 0
			progressBar.maximum = 100
			progressBar.enabled = true
			addPropertyChangeListener([
				if(progressBar.value < progress)
					progressBar.value = progress
			])
		}

		override protected doInBackground() throws Exception {
			for (var i = 0; i < fileEntry.length; i++) {
				if(isCancelled) return null

				val entry = fileEntry.get(i)

				if (!entry.directory) {
					var inputStream = file.getInputStream(entry)
					var srcImage = ImageIO.read(inputStream)
					var resized = Scalr.resize(srcImage, Scalr.Method.QUALITY, Scalr.Mode.AUTOMATIC, 200)

					var value = new ImageEntry(i, resized)
					publish(#[value])
					progress = ((i * 100) / fileEntry.length) + 1
					inputStream.close
				}
			}
			return null
		}

		override process(List<ImageEntry> list) {
			if(cancelled) return;

			for (img : list) {
				val label = previewPanel.components.get(img.index) as JLabel
				label.icon = new ImageIcon(img.image)
			}
		}

		override done() {
			progressBar.enabled = false
			progressBar.value = 0
		}
	}
}