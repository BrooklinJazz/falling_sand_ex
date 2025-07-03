let Hooks = {}

Hooks.PixelCanvas = {
    mounted() {
        this.canvas = this.el
        this.ctx = this.canvas.getContext("2d")
        this.cellSize = this.el.getAttribute("cellSize")
        // Listen for updates from server
        this.handleEvent("render_grid", ({ diffs }) => {
            this.render(diffs)
        })

        this.canvas.addEventListener("click", (event) => {
            const { x, y } = this.getCanvasCoords(event)
            this.pushEvent("click_pixel", { x, y })
        })

        // Mouse down
        this.canvas.addEventListener("mousedown", (event) => {
            this.isDrawing = true
            const { x, y } = this.getCanvasCoords(event)
            this.pushEvent("mousedown", { x, y })
        })

        // Mouse up
        this.canvas.addEventListener("mouseup", (event) => {
            this.isDrawing = false
            this.pushEvent("mouseup", {})
        })

        // Mouse move (only when dragging)
        this.canvas.addEventListener("mousemove", (event) => {
            if (this.isDrawing) {
                const { x, y } = this.getCanvasCoords(event)
                if (this.x != x || this.y != y) {
                    this.pushEvent("mousemove", { x, y })
                    this.x = x
                    this.x = y
                }
            }
        })
    },


    getCanvasCoords(event) {
        const rect = this.canvas.getBoundingClientRect()
        const scaleX = this.canvas.width / rect.width
        const scaleY = this.canvas.height / rect.height

        const pixelX = (event.clientX - rect.left) * scaleX
        const pixelY = (event.clientY - rect.top) * scaleY

        const x = Math.floor(pixelX / this.cellSize)
        const y = Math.floor(pixelY / this.cellSize)

        return { x, y }
    },

    render(diffs) {
        diffs.forEach(({ x, y, element }) => {
            switch (element) {
                case "sand":
                    this.ctx.fillStyle = "orange"
                    this.ctx.fillRect(x * this.cellSize, y * this.cellSize, this.cellSize, this.cellSize)
                    break;
                case "stone":
                    this.ctx.fillStyle = "black"
                    this.ctx.fillRect(x * this.cellSize, y * this.cellSize, this.cellSize, this.cellSize)
                    break;
                case "empty":
                    this.ctx.clearRect(x * this.cellSize, y * this.cellSize, this.cellSize, this.cellSize)
                    break;
                default:
            }
            // this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)

        })
    }
}

export default Hooks