let Hooks = {}

Hooks.PixelCanvas = {
    mounted() {
        this.canvas = this.el
        this.ctx = this.canvas.getContext("2d")
        this.cellSize = this.el.getAttribute("cellSize")
        this.shouldWait = false
        this.interval = false
        // Listen for updates from server
        this.handleEvent("render_grid", ({ diffs }) => {
            this.render(diffs)
        })
        const self = this
        this.canvas.addEventListener('mousedown', (event) => {
            self.isMouseDown = true;

            self.interval = setInterval(() => {
                const { x, y } = self.getCanvasCoords(self, event)
                console.log("INTERVAL")
                self.pushEvent("set", { x, y })
            }, 100)
        });

        this.canvas.addEventListener('mouseup', () => {
            this.isMouseDown = false;
            clearInterval(this.interval)
        });

        // Mouse move (only when dragging)

        this.canvas.addEventListener("mousemove", (event) => {
            clearInterval(this.interval)
            if (this.isMouseDown) {
                const { x, y } = self.getCanvasCoords(self, event)
                self.pushEvent("set", { x, y })
                self.interval = setInterval(() => {
                    self.pushEvent("set", { x, y })
                }, 10)
            }
        })
    },

    getCanvasCoords(context, event) {
        const rect = context.canvas.getBoundingClientRect()
        const scaleX = context.canvas.width / rect.width
        const scaleY = context.canvas.height / rect.height

        const pixelX = (event.clientX - rect.left) * scaleX
        const pixelY = (event.clientY - rect.top) * scaleY

        const x = Math.floor(pixelX / context.cellSize)
        const y = Math.floor(pixelY / context.cellSize)

        return { x, y }
    },

    render(diffs) {
        diffs.forEach(([x, y, element]) => {
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
        })
    }
}

export default Hooks