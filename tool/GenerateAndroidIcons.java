import java.awt.AlphaComposite;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.geom.Ellipse2D;
import java.awt.geom.RoundRectangle2D;
import java.awt.image.BufferedImage;
import java.io.File;
import javax.imageio.ImageIO;

/** Deterministic packaging of the supplied artwork; no redraw or recoloring. */
class GenerateAndroidIcons {
    private static final Color BACKGROUND = new Color(199, 233, 255);

    private static Graphics2D graphics(BufferedImage image) {
        Graphics2D g = image.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        return g;
    }

    private static BufferedImage resized(BufferedImage source, int size) {
        BufferedImage image = new BufferedImage(size, size, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = graphics(image);
        g.drawImage(source, 0, 0, size, size, null);
        g.dispose();
        return image;
    }

    private static BufferedImage masked(BufferedImage source, boolean circle) {
        int size = source.getWidth();
        BufferedImage image = new BufferedImage(size, size, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = graphics(image);
        g.setColor(Color.WHITE);
        if (circle) g.fill(new Ellipse2D.Double(0, 0, size, size));
        else g.fill(new RoundRectangle2D.Double(0, 0, size, size, size * .24, size * .24));
        g.setComposite(AlphaComposite.SrcIn);
        g.drawImage(source, 0, 0, null);
        g.dispose();
        return image;
    }

    private static BufferedImage adaptive(BufferedImage source, int size, boolean foregroundOnly) {
        BufferedImage image = new BufferedImage(size, size, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = graphics(image);
        if (!foregroundOnly) {
            g.setColor(BACKGROUND);
            g.fillRect(0, 0, size, size);
        }
        // Fit all supplied artwork into the Android 66dp safe region of 108dp.
        int artSize = Math.round(size * 66f / 108f);
        int offset = (size - artSize) / 2;
        g.drawImage(source, offset, offset, artSize, artSize, null);
        g.dispose();
        return image;
    }

    public static void main(String[] args) throws Exception {
        File root = new File(args.length > 0 ? args[0] : ".");
        BufferedImage source = ImageIO.read(new File(root, "assets/branding/personal_app_icon.png"));
        if (source == null || source.getWidth() != source.getHeight()) {
            throw new IllegalArgumentException("Expected a square source PNG");
        }
        String[] densities = {"mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"};
        int[] legacy = {48, 72, 96, 144, 192};
        int[] layers = {108, 162, 216, 324, 432};
        for (int i = 0; i < densities.length; i++) {
            File dir = new File(root, "android/app/src/main/res/mipmap-" + densities[i]);
            dir.mkdirs();
            BufferedImage icon = resized(source, legacy[i]);
            ImageIO.write(icon, "png", new File(dir, "ic_launcher.png"));
            ImageIO.write(masked(icon, true), "png", new File(dir, "ic_launcher_round.png"));
            ImageIO.write(adaptive(source, layers[i], true), "png", new File(dir, "ic_launcher_foreground.png"));
            BufferedImage bg = new BufferedImage(layers[i], layers[i], BufferedImage.TYPE_INT_ARGB);
            Graphics2D g = graphics(bg);
            g.setColor(BACKGROUND);
            g.fillRect(0, 0, layers[i], layers[i]);
            g.dispose();
            ImageIO.write(bg, "png", new File(dir, "ic_launcher_background.png"));
        }
        if (args.length > 1) {
            BufferedImage layer = adaptive(source, 432, false);
            BufferedImage viewport = layer.getSubimage(72, 72, 288, 288);
            BufferedImage preview = new BufferedImage(888, 304, BufferedImage.TYPE_INT_ARGB);
            Graphics2D g = graphics(preview);
            g.setColor(new Color(239, 244, 249));
            g.fillRect(0, 0, 888, 304);
            g.drawImage(resized(source, 288), 8, 8, null);
            g.drawImage(masked(viewport, true), 300, 8, null);
            g.drawImage(masked(viewport, false), 592, 8, null);
            g.dispose();
            ImageIO.write(preview, "png", new File(args[1]));
        }
        System.out.println("Generated Android launcher images from " + source.getWidth() + "px source");
    }
}
